package com.bsg.docviz.vector;

import com.bsg.docviz.config.DocvizChatProperties;
import com.bsg.docviz.config.VectorProperties;
import com.bsg.docviz.dto.ChatHistoryEntryDto;
import com.bsg.docviz.dto.RagPreparedContext;
import com.bsg.docviz.dto.TreeNodeDto;
import com.bsg.docviz.dto.VectorChatResponse;
import com.bsg.docviz.context.DocvizChatContext;
import com.bsg.docviz.security.CurrentUser;
import com.bsg.docviz.service.ChatConversationPersistenceService;
import com.bsg.docviz.service.DomainTaskService;
import com.bsg.docviz.service.FileContentCache;
import com.bsg.docviz.application.port.output.GitRepositoryPort;
import com.bsg.docviz.application.port.output.SessionRegistryPort;
import com.bsg.docviz.service.UserRepositoryState;
import com.bsg.docviz.support.SupportMarkdownConstants;
import com.bsg.docviz.support.SupportS3Service;
import com.bsg.docviz.util.RagMentionParser;
import com.bsg.docviz.util.RepoTreePathFinder;
import com.bsg.docviz.util.SourceTextExtractor;
import com.bsg.docviz.util.TaskPlanStepsParser;
import com.bsg.docviz.util.TextChunker;
import com.bsg.docviz.util.WorkAreaVersionPreference;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.ai.chat.client.ChatClient;
import org.springframework.http.HttpStatus;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;
import reactor.core.publisher.Flux;

import java.nio.file.Path;
import java.time.Duration;
import java.util.concurrent.TimeoutException;
import java.util.Locale;
import java.util.Objects;
import java.util.regex.Pattern;
import java.util.Optional;
import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;

@Service
public class VectorRagService {

    private static final Logger log = LoggerFactory.getLogger(VectorRagService.class);

    /** Prompt de sistema compacto; la pregunta concreta va en el mensaje user (contexto RAG + enunciado). */
    private static final String SYSTEM_PROMPT =
            "Eres un asistente técnico. Usa solo la información del contexto que recibes: fragmentos del repositorio "
                    + "(marcados con [Fuente: …]) y, si en ese bloque hay documentos de soporte, también esos.\n"
                    + "No inventes datos que no aparezcan ahí. Responde en español, claro y breve.\n\n"
                    + "Para la petición del usuario: primero esboza un plan corto para resolver el enunciado. "
                    + "Si la solución requiere tocar uno o más archivos (en el repo o en soporte), después del plan incluye "
                    + "los cambios en un único bloque ```yaml con raíz proposals: (no uses JSON de propuestas).\n\n"
                    + "path — prefijo obligatorio:\n"
                    + "- REPO/… → archivo del repositorio clonado (ruta relativa; el backend localiza el fichero y versiona "
                    + "borradores como _v1, _v2… sin que pongas el sufijo en path).\n"
                    + "- LOCAL/… → objeto de soporte en almacenamiento (bucket y clave en la ruta); el backend lo resuelve y "
                    + "versiona igual.\n\n"
                    + "Cada ítem: path, new (true solo si el archivo aún no existe en el repo), blocks: lista de ediciones con "
                    + "start y end (líneas 1-based), type REPLACE | NEW | DELETE, lines (strings; [] en DELETE).\n\n"
                    + "Ejemplo:\n"
                    + "```yaml\n"
                    + "proposals:\n"
                    + "- path: REPO/auth-service/docker-compose.yml\n"
                    + "  new: false\n"
                    + "  blocks:\n"
                    + "  - start: 10\n"
                    + "    end: 12\n"
                    + "    type: REPLACE\n"
                    + "    lines:\n"
                    + "    - \"  image: redis:7-alpine\"\n"
                    + "```";

    private final VectorProperties props;
    private final VectorIngestService vectorIngestService;
    private final EmbeddingClient embeddingClient;
    private final VectorStore vectorStore;
    private final GitRepositoryPort gitRepositoryService;
    private final SessionRegistryPort sessionRegistry;
    private final ChatClient chatClient;
    private final ChatConversationPersistenceService chatConversationPersistence;
    private final DocvizChatProperties chatProperties;
    private final SupportS3Service supportS3Service;

    public VectorRagService(
            VectorProperties props,
            VectorIngestService vectorIngestService,
            EmbeddingClient embeddingClient,
            VectorStore vectorStore,
            GitRepositoryPort gitRepositoryService,
            SessionRegistryPort sessionRegistry,
            ChatClient chatClient,
            ChatConversationPersistenceService chatConversationPersistence,
            DocvizChatProperties chatProperties,
            @Autowired(required = false) SupportS3Service supportS3Service
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
        this.supportS3Service = supportS3Service;
    }

    public VectorChatResponse ask(String question) {
        RagPreparedContext ctx = prepareRagOrThrow(question, null);
        String answer = String.join(
                "",
                Objects.requireNonNull(
                        streamAnswer(ctx).collectList().block(Duration.ofMinutes(15))));
        VectorChatResponse res = new VectorChatResponse();
        res.setAnswer(answer);
        res.setSources(new ArrayList<>(new LinkedHashSet<>(ctx.sources())));
        chatConversationPersistence.saveTurn(
                CurrentUser.require().trim(),
                question,
                answer,
                res.getSources(),
                ctx.repoLabel(),
                DocvizChatContext.conversationIdOrDefault());
        return res;
    }

    /**
     * Fase RAG (sin LLM): embeddings, chunks y prompt de usuario listo para {@link #streamAnswer}.
     */
    /**
     * @param rawUserUtterance texto del usuario sin prefijos de sistema (p. ej. WebSocket). Si no es nulo, las heurísticas
     *                         de área de trabajo y el embedding usan este texto — evita que el prefijo JSON contenga
     *                         palabras como «docker-compose» y dispare propuestas de archivo por error.
     */
    public RagPreparedContext prepareRagOrThrow(String question) {
        return prepareRagOrThrow(question, null);
    }

    public RagPreparedContext prepareRagOrThrow(String question, String rawUserUtterance) {
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
        String vectorStoreUserLabel = vectorIngestService.currentVectorUserLabel();
        String conversationUserId = CurrentUser.require().trim();
        log.info(
                "RAG prepare: namespace={}, vectorUserLabel={}, conversationUser={}, store={}, topK={}",
                namespace,
                vectorStoreUserLabel,
                conversationUserId,
                vectorStore.getClass().getSimpleName(),
                props.getRagTopK());
        String qEmbed = RagMentionParser.embeddingAugmentation(queryForEmbedding(question, rawUserUtterance));
        float[] qv;
        try {
            qv = embeddingClient.embedQuery(qEmbed);
        } catch (RuntimeException e) {
            log.error("RAG: embedQuery falló para la pregunta (namespace={})", namespace, e);
            throw e;
        }
        List<VectorMatch> matches;
        try {
            matches = vectorStore.queryTopK(namespace, qv, props.getRagTopK(), vectorStoreUserLabel);
        } catch (RuntimeException e) {
            log.error("RAG: queryTopK falló (namespace={})", namespace, e);
            throw e;
        }

        String rev = session.getRevisionSpec();
        FileContentCache blobCache = session.getViewerContentCache();
        String repoLabel = session.getRootFolderLabel();
        matches = WorkAreaVersionPreference.preferLatestWorkArea(matches, repoLabel);
        Set<String> seen = new LinkedHashSet<>();
        List<String> sourcesOrdered = new ArrayList<>();
        StringBuilder ctx = new StringBuilder();
        Set<String> fullInjectedSources = new LinkedHashSet<>();

        appendExplicitMentions(
                mentionSourceForParser(question, rawUserUtterance),
                session,
                root,
                rev,
                blobCache,
                repoLabel,
                ctx,
                sourcesOrdered,
                fullInjectedSources);

        if (matches.isEmpty() && ctx.isEmpty()) {
            log.warn(
                    "RAG: sin coincidencias en índice ni menciones resueltas (namespace={}, vectorUserLabel={})",
                    namespace,
                    vectorStoreUserLabel);
            throw new ResponseStatusException(HttpStatus.NOT_FOUND,
                    "No hay coincidencias en el índice para esta pregunta. Indexa archivos con POST /vector/ingest, "
                            + "o usa @[repo:ruta/al/archivo] / @[soporte:clave] en la pregunta.");
        }

        for (VectorMatch m : matches) {
            if (fullInjectedSources.contains(m.source())) {
                continue;
            }
            String key = m.source() + "|" + m.chunkIndex();
            if (!seen.add(key)) {
                continue;
            }
            try {
                String soporteKey = SupportMarkdownConstants.objectKeyFromSource(m.source());
                if (soporteKey != null) {
                    if (supportS3Service == null) {
                        log.warn("RAG: chunk de soporte sin S3; se omite fuente {}", m.source());
                        continue;
                    }
                    byte[] raw = supportS3Service.getObjectBytes(soporteKey);
                    String text = SourceTextExtractor.extractText("soporte.md", raw);
                    List<String> chunks = TextChunker.chunk(text, props.getChunkSize(), props.getChunkOverlap());
                    if (m.chunkIndex() >= chunks.size()) {
                        continue;
                    }
                    String chunk = chunks.get(m.chunkIndex());
                    ctx.append("[Fuente: ").append(m.source()).append("]\n").append(chunk).append("\n\n");
                    sourcesOrdered.add(m.source());
                    continue;
                }
                String path = repoRelativePathFromSource(m.source(), repoLabel);
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

        String repoContext = truncateRagContextIfNeeded(ctx.toString(), props.getRagMaxContextChars());
        String userBlock = buildUserPromptWithOptionalHistory(conversationUserId, question, repoContext, rawUserUtterance);
        return new RagPreparedContext(
                question,
                userBlock,
                new ArrayList<>(new LinkedHashSet<>(sourcesOrdered)),
                repoLabel != null ? repoLabel : "");
    }

    /**
     * Tokens / fragmentos de texto del modelo (streaming). Requiere {@link reactor.core.publisher.Flux} del starter reactive.
     */
    public Flux<String> streamAnswer(RagPreparedContext ctx) {
        String user = sanitizeOpenAiUserContent(ctx.userBlock());
        return chatClient.prompt()
                .system(SYSTEM_PROMPT)
                .user(user)
                .stream()
                .content();
    }

    /** OpenAI rechaza contenido con NUL (p. ej. rutas o texto corrupto en contexto RAG). */
    private static String sanitizeOpenAiUserContent(String userBlock) {
        if (userBlock == null || userBlock.isEmpty()) {
            return userBlock == null ? "" : userBlock;
        }
        return userBlock.indexOf('\u0000') < 0 ? userBlock : userBlock.replace("\u0000", "");
    }

    /**
     * Igual que {@link #streamAnswer(RagPreparedContext)} con tope de tiempo por paso (p. ej. tareas multi-paso).
     */
    public Flux<String> streamAnswer(RagPreparedContext ctx, Duration maxDuration) {
        Flux<String> flux = streamAnswer(ctx);
        if (maxDuration == null) {
            return flux;
        }
        return flux.timeout(maxDuration)
                .onErrorResume(
                        e -> e instanceof TimeoutException
                                || e.getCause() instanceof TimeoutException
                                || (e.getMessage() != null && e.getMessage().contains("Timeout")),
                        e -> Flux.just(
                                "\n\n[DocViz: tiempo de paso agotado (" + maxDuration.toMinutes() + " min)]\n\n"));
    }

    public static List<String> parsePlanSteps(String planText) {
        return TaskPlanStepsParser.parseSteps(planText);
    }

    public void persistRagTurn(RagPreparedContext ctx, String fullAnswer) {
        persistRagTurn(ctx, fullAnswer, null);
    }

    /**
     * @param questionOverrideForHistory si no es nulo, se guarda en historial en lugar de {@code ctx.question()}
     *                                   (p. ej. pregunta sin prefijo de sistema).
     */
    public void persistRagTurn(RagPreparedContext ctx, String fullAnswer, String questionOverrideForHistory) {
        String q =
                questionOverrideForHistory != null && !questionOverrideForHistory.isBlank()
                        ? questionOverrideForHistory.trim()
                        : ctx.question();
        chatConversationPersistence.saveTurn(
                CurrentUser.require().trim(),
                q,
                fullAnswer,
                ctx.sources(),
                ctx.repoLabel(),
                DocvizChatContext.conversationIdOrDefault());
    }

    /**
     * Carga por Git (cache de vista) o S3 según {@code @[repo:…]} / @{[soporte:…]} / ruta o nombre de archivo.
     */
    private void appendExplicitMentions(
            String question,
            UserRepositoryState session,
            Path root,
            String rev,
            FileContentCache blobCache,
            String repoLabel,
            StringBuilder ctx,
            List<String> sourcesOrdered,
            Set<String> fullInjectedSources) {
        List<RagMentionParser.Mention> mentions = RagMentionParser.parse(question);
        if (mentions.isEmpty()) {
            return;
        }
        TreeNodeDto tree = session.getTreeRoot();
        for (RagMentionParser.Mention men : mentions) {
            try {
                switch (men.kind()) {
                    case REPO_RELATIVE -> injectMentionRepoFile(
                            session, root, rev, blobCache, repoLabel, men.value(), ctx, sourcesOrdered, fullInjectedSources);
                    case SOPORTE_OBJECT_KEY -> injectMentionSoporte(men.value(), ctx, sourcesOrdered, fullInjectedSources);
                    case LEGACY_BASENAME -> {
                        if (tree == null) {
                            log.warn("RAG mención: sin árbol de repo para resolver {}", men.value());
                            continue;
                        }
                        Optional<String> rel = RepoTreePathFinder.findFirstPathByBasename(tree, men.value());
                        if (rel.isEmpty()) {
                            log.warn("RAG mención: no hay archivo «{}» en el repositorio", men.value());
                            continue;
                        }
                        injectMentionRepoFile(
                                session,
                                root,
                                rev,
                                blobCache,
                                repoLabel,
                                rel.get(),
                                ctx,
                                sourcesOrdered,
                                fullInjectedSources);
                    }
                }
            } catch (RuntimeException ex) {
                log.warn("RAG mención: error cargando {} — {}", men.value(), ex.toString());
            }
        }
    }

    private void injectMentionSoporte(
            String objectKey,
            StringBuilder ctx,
            List<String> sourcesOrdered,
            Set<String> fullInjectedSources) {
        if (supportS3Service == null) {
            log.warn("RAG mención soporte: S3 no disponible");
            return;
        }
        String key = objectKey.trim();
        String displaySource = SupportMarkdownConstants.sourceForObjectKey(key);
        if (fullInjectedSources.contains(displaySource)) {
            return;
        }
        byte[] raw = supportS3Service.getObjectBytes(key);
        String text = SourceTextExtractor.extractText("soporte.md", raw);
        ctx.append("[Mención explícita — documento de soporte completo: ")
                .append(displaySource)
                .append("]\n")
                .append(text)
                .append("\n\n");
        sourcesOrdered.add(displaySource);
        fullInjectedSources.add(displaySource);
    }

    private void injectMentionRepoFile(
            UserRepositoryState session,
            Path root,
            String rev,
            FileContentCache blobCache,
            String repoLabel,
            String relPathRaw,
            StringBuilder ctx,
            List<String> sourcesOrdered,
            Set<String> fullInjectedSources) {
        String rel = relPathRaw.replace('\\', '/').trim();
        if (rel.startsWith("/")) {
            rel = rel.substring(1);
        }
        if (repoLabel != null && !repoLabel.isBlank() && rel.startsWith(repoLabel + "/")) {
            rel = rel.substring(repoLabel.length() + 1);
        }
        String displaySource = (repoLabel != null && !repoLabel.isBlank()) ? repoLabel + "/" + rel : rel;
        if (fullInjectedSources.contains(displaySource)) {
            return;
        }
        long size = gitRepositoryService.objectSizeBytes(root, rev, rel);
        if (size > FileContentCache.MAX_SINGLE_FILE_BYTES) {
            log.warn("RAG mención: archivo demasiado grande {}", displaySource);
            return;
        }
        byte[] raw = blobCache.get(rel);
        if (raw == null) {
            raw = gitRepositoryService.materializeAndReadBytes(root, rev, rel);
            blobCache.put(rel, raw);
            if (session.isEphemeralManagedClone()) {
                gitRepositoryService.deleteMaterializedFileIfPresent(root, rel);
            }
        }
        String text = SourceTextExtractor.extractText(rel, raw);
        ctx.append("[Mención explícita — archivo completo: ")
                .append(displaySource)
                .append("]\n")
                .append(text)
                .append("\n\n");
        sourcesOrdered.add(displaySource);
        fullInjectedSources.add(displaySource);
    }

    /**
     * Evita superar la ventana de contexto del LLM (p. ej. Ollama HTTP 400 "input length exceeds the context length").
     */
    private String truncateRagContextIfNeeded(String text, int maxChars) {
        if (text == null || maxChars <= 0 || text.length() <= maxChars) {
            return text;
        }
        log.warn(
                "RAG: contexto del repositorio truncado de {} a {} caracteres (docviz.vector.rag-max-context-chars)",
                text.length(),
                maxChars);
        return text.substring(0, maxChars)
                + "\n\n[DocViz: contexto truncado por límite de tamaño. Acota la pregunta, reduce @[menciones] o baja docviz.vector.rag-top-k.]\n";
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

    private static String stripLeadingRagChatPrefix(String question) {
        if (question == null) {
            return "";
        }
        if (question.startsWith(DomainTaskService.RAG_CHAT_PROMPT_PREFIX)) {
            return question.substring(DomainTaskService.RAG_CHAT_PROMPT_PREFIX.length()).trim();
        }
        return question.trim();
    }

    /** Texto del usuario para @[…] y similares (sin prefijo JSON del WebSocket). */
    private static String mentionSourceForParser(String question, String rawUserUtterance) {
        if (rawUserUtterance != null && !rawUserUtterance.isBlank()) {
            return rawUserUtterance.trim();
        }
        return stripLeadingRagChatPrefix(question);
    }

    /** Pregunta efectiva para embedding (evita que el prefijo del sistema desvíe la búsqueda vectorial). */
    private static String queryForEmbedding(String question, String rawUserUtterance) {
        String base = mentionSourceForParser(question, rawUserUtterance);
        return base.isBlank() ? question : base;
    }

    /**
     * Incluye turnos previos desde Firestore (mismo {@code userId}) para continuidad del diálogo.
     */
    private String buildUserPromptWithOptionalHistory(
            String userLabel, String question, String repoContext, String rawUserUtterance) {
        String hintSource = mentionSourceForParser(question, rawUserUtterance);
        String workHint = workAreaInstructionIfNeeded(hintSource);
        int maxTurns = chatProperties.getHistoryMaxTurns();
        String displayQuestion = mentionSourceForParser(question, rawUserUtterance);
        if (displayQuestion.isBlank()) {
            displayQuestion = question;
        }
        if (maxTurns <= 0) {
            return "Contexto del repositorio:\n\n" + repoContext + workHint + "\nPregunta: " + displayQuestion;
        }
        List<ChatHistoryEntryDto> past =
                chatConversationPersistence.loadRecentTurns(userLabel, maxTurns, DocvizChatContext.conversationIdOrDefault());
        String hist = formatHistoryForPrompt(past, chatProperties.getHistoryAnswerMaxChars());
        if (hist.isEmpty()) {
            return "Contexto del repositorio:\n\n" + repoContext + workHint + "\nPregunta: " + displayQuestion;
        }
        return "Conversación previa (mismo usuario):\n\n"
                + hist
                + "---\nContexto del repositorio (para la pregunta actual):\n\n"
                + repoContext
                + workHint
                + "\nPregunta actual: "
                + displayQuestion;
    }

    /**
     * Si el usuario pide copia/sobrescritura o usa @[archivo], se fuerza la inclusión del JSON de propuestas (área de trabajo).
     */
    private static boolean questionImpliesFileProposal(String q) {
        if (q == null || q.isBlank()) {
            return false;
        }
        if (q.contains("@[")) {
            return true;
        }
        String lower = q.toLowerCase(Locale.ROOT);
        if (lower.contains("sobrees") || lower.contains("sobrescrib") || lower.contains("sobreescrib")) {
            return true;
        }
        if (lower.contains("reemplaz") && (lower.contains("archivo") || lower.contains(".md") || lower.contains(".java"))) {
            return true;
        }
        if ((lower.contains("copia") || lower.contains("nueva versión") || lower.contains("nueva version"))
                && (lower.contains("archivo") || lower.contains(".md") || lower.contains(".java"))) {
            return true;
        }
        if (lower.contains("genera") && (lower.contains("archivo") || lower.contains("copia"))) {
            return true;
        }
        if ((lower.contains("quita") || lower.contains("elimina") || lower.contains("borra"))
                && (lower.contains("documento") || lower.contains("archivo") || lower.contains(".md"))) {
            return true;
        }
        if (lower.contains("_v1")) {
            return true;
        }
        if (Pattern.compile("(?i)_v\\d+").matcher(q).find()) {
            return true;
        }
        if ((lower.contains("docker-compose") || lower.contains("docker compose"))
                && (lower.contains("quita")
                        || lower.contains("elimina")
                        || lower.contains("borra")
                        || lower.contains("sin ")
                        || lower.contains("modifica")
                        || lower.contains("ajusta")
                        || lower.contains("añade")
                        || lower.contains("agrega"))) {
            return true;
        }
        if ((lower.contains(".yml") || lower.contains(".yaml") || lower.contains(".properties"))
                && (lower.contains("quita") || lower.contains("elimina") || lower.contains("borra")
                        || lower.contains("sin ") || lower.contains("modifica") || lower.contains("ajusta"))) {
            return true;
        }
        return false;
    }

    private static String workAreaInstructionIfNeeded(String question) {
        if (!questionImpliesFileProposal(question)) {
            return "";
        }
        return "\n\n[DocViz — requisito] Tras el plan breve, incluye un único bloque ```yaml con proposals: "
                + "(path REPO/… o LOCAL/…, new, blocks). Sin ese YAML no se puede generar el borrador versionado.";
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
