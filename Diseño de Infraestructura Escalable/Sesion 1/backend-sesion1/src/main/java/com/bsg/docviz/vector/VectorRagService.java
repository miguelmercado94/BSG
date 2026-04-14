package com.bsg.docviz.vector;

import com.bsg.docviz.config.DocvizChatProperties;
import com.bsg.docviz.config.VectorProperties;
import com.bsg.docviz.dto.ChatHistoryEntryDto;
import com.bsg.docviz.dto.VectorChatResponse;
import com.bsg.docviz.security.CurrentUser;
import com.bsg.docviz.service.ChatConversationPersistenceService;
import com.bsg.docviz.service.FileContentCache;
import com.bsg.docviz.service.GitRepositoryService;
import com.bsg.docviz.service.SessionRegistry;
import com.bsg.docviz.util.SourceTextExtractor;
import com.bsg.docviz.util.TextChunker;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.ai.chat.client.ChatClient;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.nio.file.Path;
import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;

@Service
public class VectorRagService {

    private static final Logger log = LoggerFactory.getLogger(VectorRagService.class);

    private static final String SYSTEM_PROMPT =
            "Eres un asistente técnico. Responde usando únicamente el contexto del repositorio que se te proporciona "
                    + "(fragmentos bajo cada [Fuente: …]).\n"
                    + "Si la pregunta pide dependencias, versiones o listas concretas, extrae lo que aparezca literalmente "
                    + "en ese texto (p. ej. bloques Maven/Gradle, tablas, viñetas); no sustituyas por una lista genérica "
                    + "de Spring si el contexto ya detalla artefactos o coordenadas.\n"
                    + "Si el contexto no contiene la información, dilo sin inventar. Responde en español de forma concisa.";

    private final VectorProperties props;
    private final VectorIngestService vectorIngestService;
    private final EmbeddingClient embeddingClient;
    private final VectorStore vectorStore;
    private final GitRepositoryService gitRepositoryService;
    private final SessionRegistry sessionRegistry;
    private final ChatClient chatClient;
    private final ChatConversationPersistenceService chatConversationPersistence;
    private final DocvizChatProperties chatProperties;

    public VectorRagService(
            VectorProperties props,
            VectorIngestService vectorIngestService,
            EmbeddingClient embeddingClient,
            VectorStore vectorStore,
            GitRepositoryService gitRepositoryService,
            SessionRegistry sessionRegistry,
            ChatClient chatClient,
            ChatConversationPersistenceService chatConversationPersistence,
            DocvizChatProperties chatProperties
    ) {
        this.props = props;
        this.vectorIngestService = vectorIngestService;
        this.embeddingClient = embeddingClient;
        this.vectorStore = vectorStore;
        this.gitRepositoryService = gitRepositoryService;
        this.sessionRegistry = sessionRegistry;
        this.chatClient = chatClient;
        this.chatConversationPersistence = chatConversationPersistence;
        this.chatProperties = chatProperties;
    }

    public VectorChatResponse ask(String question) {
        if (!props.isEnabled()) {
            throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE,
                    "Vector store deshabilitado (docviz.vector.enabled=false)");
        }
        var session = sessionRegistry.current();
        if (!session.isConnected()) {
            throw new IllegalStateException("Not connected to a repository");
        }
        Path root = session.getRepositoryRoot();
        if (root == null) {
            throw new IllegalStateException("Not connected to a repository");
        }

        String namespace = vectorIngestService.currentNamespace();
        String userLabel = CurrentUser.require().trim();
        log.info(
                "RAG ask: namespace={}, userLabel={}, store={}, topK={}",
                namespace,
                userLabel,
                vectorStore.getClass().getSimpleName(),
                props.getRagTopK());
        float[] qv;
        try {
            qv = embeddingClient.embedQuery(question);
        } catch (RuntimeException e) {
            log.error("RAG: embedQuery falló para la pregunta (namespace={})", namespace, e);
            throw e;
        }
        List<VectorMatch> matches;
        try {
            matches = vectorStore.queryTopK(namespace, qv, props.getRagTopK(), userLabel);
        } catch (RuntimeException e) {
            log.error("RAG: queryTopK falló (namespace={})", namespace, e);
            throw e;
        }

        if (matches.isEmpty()) {
            log.warn("RAG: sin coincidencias en índice (namespace={}, userLabel={})", namespace, userLabel);
            throw new ResponseStatusException(HttpStatus.NOT_FOUND,
                    "No hay coincidencias en el índice para esta pregunta. Indexa archivos con POST /vector/ingest.");
        }

        String rev = session.getRevisionSpec();
        FileContentCache blobCache = session.getViewerContentCache();
        String repoLabel = session.getRootFolderLabel();
        Set<String> seen = new LinkedHashSet<>();
        List<String> sourcesOrdered = new ArrayList<>();
        StringBuilder ctx = new StringBuilder();

        for (VectorMatch m : matches) {
            String key = m.source() + "|" + m.chunkIndex();
            if (!seen.add(key)) {
                continue;
            }
            String path = repoRelativePathFromSource(m.source(), repoLabel);
            try {
                long size = gitRepositoryService.objectSizeBytes(root, rev, path);
                if (size > FileContentCache.MAX_SINGLE_FILE_BYTES) {
                    continue;
                }
                byte[] raw = blobCache.get(path);
                if (raw == null) {
                    raw = gitRepositoryService.materializeAndReadBytes(root, rev, path);
                    blobCache.put(path, raw);
                    if (session.isEphemeralManagedClone()) {
                        gitRepositoryService.deleteMaterializedFileIfPresent(root, path);
                    }
                }
                String text = SourceTextExtractor.extractText(path, raw);
                List<String> chunks = TextChunker.chunk(text, props.getChunkSize(), props.getChunkOverlap());
                if (m.chunkIndex() >= chunks.size()) {
                    continue;
                }
                String chunk = chunks.get(m.chunkIndex());
                ctx.append("[Fuente: ").append(m.source()).append("]\n").append(chunk).append("\n\n");
                sourcesOrdered.add(m.source());
            } catch (RuntimeException ex) {
                log.warn("RAG: no se pudo cargar chunk para fuente {} — {}", m.source(), ex.toString());
            }
        }

        if (ctx.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "No se pudo reconstruir texto desde el índice. Vuelve a indexar.");
        }

        String userBlock = buildUserPromptWithOptionalHistory(userLabel, question, ctx.toString());

        String answer = chatClient.prompt()
                .system(SYSTEM_PROMPT)
                .user(userBlock)
                .call()
                .content();

        VectorChatResponse res = new VectorChatResponse();
        res.setAnswer(answer);
        res.setSources(new ArrayList<>(new LinkedHashSet<>(sourcesOrdered)));

        chatConversationPersistence.saveTurn(userLabel, question, answer, res.getSources(), repoLabel);

        return res;
    }

    private static String repoRelativePathFromSource(String sourceDisplay, String repoLabel) {
        if (repoLabel == null || repoLabel.isBlank()) {
            return sourceDisplay;
        }
        String prefix = repoLabel + "/";
        if (sourceDisplay.startsWith(prefix)) {
            return sourceDisplay.substring(prefix.length());
        }
        return sourceDisplay;
    }

    /**
     * Incluye turnos previos desde Firestore (mismo {@code userId}) para continuidad del diálogo.
     */
    private String buildUserPromptWithOptionalHistory(String userLabel, String question, String repoContext) {
        int maxTurns = chatProperties.getHistoryMaxTurns();
        if (maxTurns <= 0) {
            return "Contexto del repositorio:\n\n" + repoContext + "\nPregunta: " + question;
        }
        List<ChatHistoryEntryDto> past = chatConversationPersistence.loadRecentTurns(userLabel, maxTurns);
        String hist = formatHistoryForPrompt(past, chatProperties.getHistoryAnswerMaxChars());
        if (hist.isEmpty()) {
            return "Contexto del repositorio:\n\n" + repoContext + "\nPregunta: " + question;
        }
        return "Conversación previa (mismo usuario):\n\n"
                + hist
                + "---\nContexto del repositorio (para la pregunta actual):\n\n"
                + repoContext
                + "\nPregunta actual: "
                + question;
    }

    private static String formatHistoryForPrompt(List<ChatHistoryEntryDto> turns, int maxAnswerChars) {
        if (turns == null || turns.isEmpty()) {
            return "";
        }
        StringBuilder sb = new StringBuilder();
        for (ChatHistoryEntryDto t : turns) {
            String q = t.getQuestion() != null ? t.getQuestion() : "";
            String ans = t.getAnswer() != null ? t.getAnswer() : "";
            if (ans.length() > maxAnswerChars) {
                ans = ans.substring(0, maxAnswerChars) + "…";
            }
            sb.append("Usuario: ").append(q).append('\n');
            sb.append("Asistente: ").append(ans).append("\n\n");
        }
        return sb.toString();
    }
}
