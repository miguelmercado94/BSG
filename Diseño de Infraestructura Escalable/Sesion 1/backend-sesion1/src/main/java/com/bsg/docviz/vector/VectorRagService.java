package com.bsg.docviz.vector;

import com.bsg.docviz.config.VectorProperties;
import com.bsg.docviz.dto.VectorChatResponse;
import com.bsg.docviz.security.CurrentUser;
import com.bsg.docviz.service.FileContentCache;
import com.bsg.docviz.service.GitRepositoryService;
import com.bsg.docviz.service.SessionRegistry;
import com.bsg.docviz.util.SourceTextExtractor;
import com.bsg.docviz.util.TextChunker;
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

    private static final String SYSTEM_PROMPT =
            "Eres un asistente técnico. Responde usando únicamente el contexto del repositorio que se te proporciona.\n"
                    + "Si el contexto no basta, dilo con claridad. Responde en español de forma concisa.";

    private final VectorProperties props;
    private final VectorIngestService vectorIngestService;
    private final PineconeVectorClient pinecone;
    private final GitRepositoryService gitRepositoryService;
    private final SessionRegistry sessionRegistry;
    private final ChatClient chatClient;

    public VectorRagService(
            VectorProperties props,
            VectorIngestService vectorIngestService,
            PineconeVectorClient pinecone,
            GitRepositoryService gitRepositoryService,
            SessionRegistry sessionRegistry,
            ChatClient chatClient
    ) {
        this.props = props;
        this.vectorIngestService = vectorIngestService;
        this.pinecone = pinecone;
        this.gitRepositoryService = gitRepositoryService;
        this.sessionRegistry = sessionRegistry;
        this.chatClient = chatClient;
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
        String indexHost = pinecone.getIndexHost();
        float[] qv = pinecone.embedQuery(question);
        String userLabel = CurrentUser.require().trim();
        List<PineconeMatch> matches = pinecone.queryTopK(
                indexHost, namespace, qv, props.getRagTopK(), userLabel);

        if (matches.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND,
                    "No hay coincidencias en el índice para esta pregunta. Indexa archivos con POST /vector/ingest.");
        }

        String rev = session.getRevisionSpec();
        FileContentCache blobCache = session.getViewerContentCache();
        String repoLabel = session.getRootFolderLabel();
        Set<String> seen = new LinkedHashSet<>();
        List<String> sourcesOrdered = new ArrayList<>();
        StringBuilder ctx = new StringBuilder();

        for (PineconeMatch m : matches) {
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
            } catch (RuntimeException ignored) {
                // omitir
            }
        }

        if (ctx.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "No se pudo reconstruir texto desde el índice. Vuelve a indexar.");
        }

        String userBlock = "Contexto del repositorio:\n\n" + ctx + "\nPregunta: " + question;
        String answer = chatClient.prompt()
                .system(SYSTEM_PROMPT)
                .user(userBlock)
                .call()
                .content();

        VectorChatResponse res = new VectorChatResponse();
        res.setAnswer(answer);
        res.setSources(new ArrayList<>(new LinkedHashSet<>(sourcesOrdered)));
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
}
