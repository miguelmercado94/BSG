package com.bsg.docviz.vector;

import com.bsg.docviz.config.VectorProperties;
import com.bsg.docviz.dto.IngestProgressDto;
import com.bsg.docviz.dto.VectorIngestResponse;
import com.bsg.docviz.security.CurrentUser;
import com.bsg.docviz.security.UserIdSanitizer;
import com.bsg.docviz.service.FileContentCache;
import com.bsg.docviz.application.port.output.GitRepositoryPort;
import com.bsg.docviz.application.port.output.SessionRegistryPort;
import com.bsg.docviz.util.RepoPathExclude;
import com.bsg.docviz.util.SourceTextExtractor;
import com.bsg.docviz.util.TextChunker;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.core.io.ClassPathResource;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.UUID;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;
import java.util.function.Consumer;

@Service
public class VectorIngestService {

    private static final Logger log = LoggerFactory.getLogger(VectorIngestService.class);

    /**
     * Etiqueta de usuario en el almacén vectorial cuando el ámbito es el namespace de célula (índice compartido),
     * no el usuario DocViz. Debe coincidir entre ingesta admin (namespace explícito) y consultas RAG con sesión alineada.
     */
    public static final String SHARED_VECTOR_USER_LABEL = "__DOCVIZ_NS__";

    /** Archivos a precargar por delante del actual (pila/cola acotada: 1 actual + 4 prefetch = 5). */
    private static final int PREFETCH_AHEAD = 4;

    private final VectorProperties props;
    private final EmbeddingClient embeddingClient;
    private final VectorStore vectorStore;
    private final GitRepositoryPort gitRepositoryService;
    private final SessionRegistryPort sessionRegistry;

    public VectorIngestService(
            VectorProperties props,
            EmbeddingClient embeddingClient,
            VectorStore vectorStore,
            GitRepositoryPort gitRepositoryService,
            SessionRegistryPort sessionRegistry
    ) {
        this.props = props;
        this.embeddingClient = embeddingClient;
        this.vectorStore = vectorStore;
        this.gitRepositoryService = gitRepositoryService;
        this.sessionRegistry = sessionRegistry;
    }

    public String currentNamespace() {
        var s = sessionRegistry.current();
        String ov = s.getVectorNamespaceOverride();
        if (ov != null && !ov.isBlank()) {
            return ov.trim();
        }
        String user = UserIdSanitizer.forFilesystem(CurrentUser.require());
        String label = s.getRootFolderLabel() != null ? s.getRootFolderLabel() : "repo";
        return user + "__" + label.replaceAll("[^a-zA-Z0-9._-]", "_");
    }

    /**
     * Etiqueta para upsert/query en el vector store: usuario DocViz salvo sesión con namespace de célula explícito.
     */
    public String currentVectorUserLabel() {
        var s = sessionRegistry.current();
        if (s.getVectorNamespaceOverride() != null && !s.getVectorNamespaceOverride().isBlank()) {
            return SHARED_VECTOR_USER_LABEL;
        }
        return CurrentUser.require().trim();
    }

    /**
     * Ingesta Markdown de soporte (objeto ya en S3). {@code displaySource} debe ser
     * {@link com.bsg.docviz.support.SupportMarkdownConstants#sourceForObjectKey(String)}.
     */
    public VectorIngestResponse ingestSupportPlainText(String displaySource, String text) {
        if (!props.isEnabled()) {
            throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE, "Vector store disabled");
        }
        var session = sessionRegistry.current();
        if (!session.isConnected()) {
            throw new IllegalStateException("Not connected to a repository");
        }
        if (text == null || text.isBlank()) {
            throw new IllegalArgumentException("El Markdown está vacío");
        }
        String ns = currentNamespace();
        String userLabel = currentVectorUserLabel();
        vectorStore.deleteBySource(ns, displaySource);
        List<String> parts = TextChunker.chunk(text, props.getChunkSize(), props.getChunkOverlap());
        List<VectorRecord> batch = new ArrayList<>();
        int[] chunksRef = new int[] {0};
        appendEmbeddingsForParts(
                parts,
                displaySource,
                ns,
                userLabel,
                1,
                0,
                displaySource,
                null,
                batch,
                chunksRef);
        if (!batch.isEmpty()) {
            flushVectorBatch(ns, batch);
        }
        VectorIngestResponse r = new VectorIngestResponse();
        r.setFilesProcessed(1);
        r.setChunksIndexed(chunksRef[0]);
        r.setSkipped(new ArrayList<>());
        r.setNamespace(ns);
        return r;
    }

    /**
     * Indexa un borrador del área de trabajo (copia sugerida por el LLM, p. ej. {@code Foo_v1.java}) en el namespace
     * actual. La fuente mostrada en RAG es {@code &lt;raíz-repo&gt;/workarea/&lt;nombreSeguro&gt;}.
     */
    public VectorIngestResponse ingestWorkAreaFile(String fileName, String content) {
        if (!props.isEnabled()) {
            throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE, "Vector store disabled");
        }
        var session = sessionRegistry.current();
        if (!session.isConnected()) {
            throw new IllegalStateException("Not connected to a repository");
        }
        if (fileName == null || fileName.isBlank()) {
            throw new IllegalArgumentException("fileName es obligatorio");
        }
        if (content == null || content.isBlank()) {
            throw new IllegalArgumentException("El contenido está vacío");
        }
        String safe = sanitizeWorkAreaFileName(fileName);
        String label = session.getRootFolderLabel() != null ? session.getRootFolderLabel() : "repo";
        String displaySource = label + "/workarea/" + safe;
        return ingestSupportPlainText(displaySource, content);
    }

    /**
     * Elimina fragmentos vectoriales para la misma fuente virtual que {@link #ingestWorkAreaFile(String, String)} (p. ej.
     * al borrar el objeto correspondiente en S3 workarea).
     */
    public void deleteWorkAreaRagByFileName(String fileName) {
        if (!props.isEnabled()) {
            return;
        }
        var session = sessionRegistry.current();
        if (!session.isConnected()) {
            return;
        }
        if (fileName == null || fileName.isBlank()) {
            return;
        }
        String safe = sanitizeWorkAreaFileName(fileName);
        String label = session.getRootFolderLabel() != null ? session.getRootFolderLabel() : "repo";
        String displaySource = label + "/workarea/" + safe;
        String ns = currentNamespace();
        vectorStore.deleteBySource(ns, displaySource);
    }

    private static String sanitizeWorkAreaFileName(String fileName) {
        String n = fileName.replace('\\', '/').trim();
        int slash = n.lastIndexOf('/');
        if (slash >= 0) {
            n = n.substring(slash + 1);
        }
        if (n.isEmpty() || n.contains("..")) {
            throw new IllegalArgumentException("Nombre de archivo inválido");
        }
        return n;
    }

    /**
     * Ingesta Markdown de soporte en un namespace explícito (admin / repositorio de célula sin sesión Git).
     * Usa {@link #SHARED_VECTOR_USER_LABEL} como etiqueta de usuario en el vector store.
     */
    public VectorIngestResponse ingestSupportPlainTextForNamespace(String namespace, String displaySource, String text) {
        if (!props.isEnabled()) {
            throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE, "Vector store disabled");
        }
        if (namespace == null || namespace.isBlank()) {
            throw new IllegalArgumentException("namespace requerido");
        }
        if (text == null || text.isBlank()) {
            throw new IllegalArgumentException("El Markdown está vacío");
        }
        String ns = namespace.trim();
        String userLabel = SHARED_VECTOR_USER_LABEL;
        vectorStore.deleteBySource(ns, displaySource);
        List<String> parts = TextChunker.chunk(text, props.getChunkSize(), props.getChunkOverlap());
        List<VectorRecord> batch = new ArrayList<>();
        int[] chunksRef = new int[] {0};
        appendEmbeddingsForParts(
                parts,
                displaySource,
                ns,
                userLabel,
                1,
                0,
                displaySource,
                null,
                batch,
                chunksRef);
        if (!batch.isEmpty()) {
            flushVectorBatch(ns, batch);
        }
        VectorIngestResponse r = new VectorIngestResponse();
        r.setFilesProcessed(1);
        r.setChunksIndexed(chunksRef[0]);
        r.setSkipped(new ArrayList<>());
        r.setNamespace(ns);
        return r;
    }

    /**
     * Borra todos los vectores del namespace del repo actual (equivalente a vaciar namespace en Pinecone).
     */
    public String clearCurrentNamespaceIndex() {
        if (!props.isEnabled()) {
            throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE, "Vector store disabled");
        }
        var session = sessionRegistry.current();
        if (!session.isConnected()) {
            throw new IllegalStateException("Not connected to a repository");
        }
        String ns = currentNamespace();
        vectorStore.deleteAllInNamespace(ns);
        log.info("Índice vectorial vaciado para namespace={} (store={})", ns, vectorStore.getClass().getSimpleName());
        return ns;
    }

    /** Borra todos los vectores del namespace indicado (p. ej. al descartar un repo huérfano indexado). */
    public void clearNamespace(String namespace) {
        if (!props.isEnabled()) {
            return;
        }
        if (namespace == null || namespace.isBlank()) {
            return;
        }
        vectorStore.deleteAllInNamespace(namespace.trim());
        log.info("clearNamespace: namespace={} (store={})", namespace, vectorStore.getClass().getSimpleName());
    }

    public VectorIngestResponse ingestAll() {
        return ingestAll(null, null);
    }

    /**
     * Ingesta con eventos de progreso (START, FILE, PROGRESS por archivo indexado, DONE).
     * Si {@code onProgress} es null, no se emiten eventos.
     */
    public VectorIngestResponse ingestAll(Consumer<IngestProgressDto> onProgress) {
        return ingestAll(onProgress, null);
    }

    /**
     * Igual que {@link #ingestAll(Consumer)} pero fija el namespace vectorial (p. ej. repositorio de célula en BD).
     */
    public VectorIngestResponse ingestAll(Consumer<IngestProgressDto> onProgress, String namespaceOverride) {
        if (props.isIngestClasspathSampleOnly()) {
            return ingestClasspathSampleOnly(onProgress);
        }
        if (!props.isEnabled()) {
            throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE, "Vector store disabled");
        }
        var session = sessionRegistry.current();
        if (!session.isConnected()) {
            throw new IllegalStateException("Not connected to a repository");
        }
        Path root = session.getRepositoryRoot();
        if (root == null) {
            throw new IllegalStateException("Not connected to a repository");
        }
        FileContentCache blobCache = session.getIngestContentCache();
        String rev = session.getRevisionSpec();
        String ns =
                namespaceOverride != null && !namespaceOverride.isBlank()
                        ? namespaceOverride.trim()
                        : currentNamespace();
        String userLabel =
                namespaceOverride != null && !namespaceOverride.isBlank()
                        ? SHARED_VECTOR_USER_LABEL
                        : CurrentUser.require().trim();

        List<String> paths;
        try {
            paths = gitRepositoryService.listTrackedFiles(root, rev);
        } catch (Exception e) {
            throw new IllegalStateException("Cannot list files: " + e.getMessage(), e);
        }
        int pathsFromGit = paths.size();
        paths = RepoPathExclude.filterWorkspacePaths(paths);
        if (pathsFromGit != paths.size()) {
            log.info(
                    "Ingesta: excluidas {} rutas (target/, node_modules/, build/, …): {} → {} archivos",
                    pathsFromGit - paths.size(),
                    pathsFromGit,
                    paths.size());
        }

        List<String> skipped = new ArrayList<>();
        for (String rel : paths) {
            if (!isIndexablePath(rel)) {
                skipped.add(rel + " (tipo no indexable)");
            }
        }
        List<String> indexable = new ArrayList<>();
        for (String rel : paths) {
            if (isIndexablePath(rel)) {
                indexable.add(rel);
            }
        }
        int totalIndexable = indexable.size();
        if (totalIndexable == 0 && pathsFromGit > 0) {
            log.warn(
                    "Vector ingest: 0 archivos indexables de {} rutas tras filtros (revisión {}). "
                            + "¿Solo binarios/config? ¿Rutas bajo carpeta sin Git? Primeros omitidos (tipo): {}",
                    pathsFromGit,
                    rev,
                    skipped.stream().limit(12).toList());
        }
        log.info(
                "Vector ingest start: user={}, namespace={}, indexableFiles={}, revision={}",
                userLabel,
                ns,
                totalIndexable,
                rev);
        log.info(
                "Vector ingest config: store={}, embeddingsProvider={}, embeddingDim={}, embedChunkBatchSize={}, "
                        + "vectorStore={}, embeddingClient={}",
                props.getStore(),
                props.getEmbeddingsProvider(),
                props.getEmbeddingDimensions(),
                props.getEmbedChunkBatchSize(),
                vectorStore.getClass().getSimpleName(),
                embeddingClient.getClass().getSimpleName());
        if (onProgress != null) {
            onProgress.accept(IngestProgressDto.start(totalIndexable));
        }

        int files = 0;
        int chunks = 0;
        List<VectorRecord> batch = new ArrayList<>();

        // Hilos virtuales (Java 21+) evitados aquí: en JRE 17 o bytecode mezclado provoca
        // "newVirtualThreadPerTaskExecutor() is undefined". Cached pool es compatible y suficiente para prefetch.
        // Pool acotado: CachedThreadPool crece sin techo y en Fargate (poca RAM/CPU) puede tumbar el REST junto a la ingesta.
        int prefetchThreads = Math.min(PREFETCH_AHEAD + 2, 8);
        ExecutorService prefetchPool = props.isPrefetchUsePlatformThreads()
                ? Executors.newFixedThreadPool(Math.min(PREFETCH_AHEAD, 4))
                : Executors.newFixedThreadPool(
                        prefetchThreads,
                        r -> {
                            Thread t = new Thread(r, "docviz-prefetch");
                            t.setDaemon(true);
                            return t;
                        });
        try {
            for (int i = 0; i < indexable.size(); i++) {
                String rel = indexable.get(i);
                submitPrefetchAhead(indexable, i, root, rev, blobCache, prefetchPool, session.isEphemeralManagedClone());
                if (onProgress != null) {
                    IngestProgressDto fileEv = IngestProgressDto.file(totalIndexable, files, chunks, rel);
                    fileEv.setDetail("Leyendo desde Git…");
                    onProgress.accept(fileEv);
                }
                try {
                    long size = gitRepositoryService.objectSizeBytes(root, rev, rel);
                    if (size > FileContentCache.MAX_SINGLE_FILE_BYTES) {
                        skipped.add(rel + " (muy grande)");
                        continue;
                    }
                    byte[] raw = blobCache.get(rel);
                    if (raw == null) {
                        raw = gitRepositoryService.materializeAndReadBytes(root, rev, rel);
                        blobCache.put(rel, raw);
                    }
                    String text = SourceTextExtractor.extractText(rel, raw);
                    if (text == null || text.isBlank()) {
                        skipped.add(rel + " (sin texto)");
                        continue;
                    }
                    List<String> parts = TextChunker.chunk(text, props.getChunkSize(), props.getChunkOverlap());
                    log.info(
                            "Ingest file {}/{}: {} ({} chunks)",
                            i + 1,
                            totalIndexable,
                            rel,
                            parts.size());
                    String displaySource = session.getRootFolderLabel() + "/" + rel;
                    vectorStore.deleteBySource(ns, displaySource);
                    int[] chunksRef = new int[] {chunks};
                    appendEmbeddingsForParts(
                            parts,
                            displaySource,
                            ns,
                            userLabel,
                            totalIndexable,
                            files,
                            rel,
                            onProgress,
                            batch,
                            chunksRef);
                    chunks = chunksRef[0];
                    files++;
                    if (onProgress != null) {
                        onProgress.accept(IngestProgressDto.progress(totalIndexable, files, chunks, rel));
                    }
                } catch (RuntimeException ex) {
                    log.error("Vector ingest: error al procesar {} — {}", rel, ex.toString(), ex);
                    skipped.add(rel + ": " + ex.getMessage());
                } finally {
                    blobCache.remove(rel);
                    if (session.isEphemeralManagedClone()) {
                        gitRepositoryService.deleteMaterializedFileIfPresent(root, rel);
                    }
                }
            }
        } finally {
            prefetchPool.shutdown();
            try {
                if (!prefetchPool.awaitTermination(30, TimeUnit.MINUTES)) {
                    prefetchPool.shutdownNow();
                }
            } catch (InterruptedException e) {
                prefetchPool.shutdownNow();
                Thread.currentThread().interrupt();
            }
        }
        if (!batch.isEmpty()) {
            log.info("Vector ingest: volcando lote final a almacén ({} filas pendientes)", batch.size());
            flushVectorBatch(ns, batch);
        }

        VectorIngestResponse r = new VectorIngestResponse();
        r.setFilesProcessed(files);
        r.setChunksIndexed(chunks);
        r.setSkipped(skipped);
        r.setNamespace(ns);
        log.info(
                "Vector ingest done: namespace={}, filesProcessed={}, chunksIndexed={}, skippedLines={}. "
                        + "Verificar pgvector: SELECT COUNT(*) FROM docviz_vector_chunk WHERE namespace = '{}'; "
                        + "RAG requiere misma sesión Git con vectorNamespace (user_label='{}').",
                ns,
                files,
                chunks,
                skipped.size(),
                ns,
                userLabel);
        if (onProgress != null) {
            onProgress.accept(IngestProgressDto.done(r));
        }
        return r;
    }

    /**
     * Ingesta única: texto desde {@code src/main/resources} (sin Git). Misma pipeline embed + upsert que un archivo del repo.
     */
    private VectorIngestResponse ingestClasspathSampleOnly(Consumer<IngestProgressDto> onProgress) {
        if (!props.isEnabled()) {
            throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE, "Vector store disabled");
        }
        var session = sessionRegistry.current();
        if (!session.isConnected()) {
            throw new IllegalStateException("Not connected to a repository");
        }
        String resourcePath = props.getClasspathSampleResource();
        ClassPathResource res = new ClassPathResource(resourcePath);
        if (!res.exists()) {
            throw new IllegalStateException("No existe en classpath: " + resourcePath);
        }
        final String text;
        try (InputStream in = res.getInputStream()) {
            text = new String(in.readAllBytes(), StandardCharsets.UTF_8);
        } catch (IOException e) {
            throw new IllegalStateException("No se pudo leer el sample classpath: " + e.getMessage(), e);
        }
        if (text.isBlank()) {
            throw new IllegalStateException("El archivo classpath está vacío: " + resourcePath);
        }

        String ns = currentNamespace();
        String userLabel = currentVectorUserLabel();
        String displaySource = "classpath:" + resourcePath;
        int totalIndexable = 1;
        List<String> skipped = new ArrayList<>();

        if (onProgress != null) {
            onProgress.accept(IngestProgressDto.start(totalIndexable));
        }
        if (onProgress != null) {
            onProgress.accept(IngestProgressDto.file(totalIndexable, 0, 0, resourcePath));
        }

        vectorStore.deleteBySource(ns, displaySource);
        List<String> parts = TextChunker.chunk(text, props.getChunkSize(), props.getChunkOverlap());
        List<VectorRecord> batch = new ArrayList<>();
        int files = 0;
        int chunks = 0;
        int[] chunksRef = new int[] {0};
        appendEmbeddingsForParts(
                parts,
                displaySource,
                ns,
                userLabel,
                totalIndexable,
                0,
                resourcePath,
                onProgress,
                batch,
                chunksRef);
        chunks = chunksRef[0];
        files = 1;
        if (onProgress != null) {
            onProgress.accept(IngestProgressDto.progress(totalIndexable, files, chunks, resourcePath));
        }
        if (!batch.isEmpty()) {
            flushVectorBatch(ns, batch);
        }

        VectorIngestResponse r = new VectorIngestResponse();
        r.setFilesProcessed(files);
        r.setChunksIndexed(chunks);
        r.setSkipped(skipped);
        r.setNamespace(ns);
        if (onProgress != null) {
            onProgress.accept(IngestProgressDto.done(r));
        }
        return r;
    }

    /** Escribe un lote al {@link VectorStore} con logs y manejo de error explícito. */
    private void flushVectorBatch(String ns, List<VectorRecord> batch) {
        int n = batch.size();
        try {
            log.info(
                    "Almacén vectorial: upsert de {} filas (namespace={}, store={})",
                    n,
                    ns,
                    vectorStore.getClass().getSimpleName());
            vectorStore.upsertBatch(ns, batch);
            log.info("Almacén vectorial: upsert correcto — {} filas (namespace={})", n, ns);
        } catch (RuntimeException e) {
            log.error("Almacén vectorial: upsert falló — {} filas, namespace={}", n, ns, e);
            throw e;
        }
        batch.clear();
        sleepDelay();
    }

    private void sleepDelay() {
        try {
            Thread.sleep(props.getEmbedBatchDelayMs());
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }

    /**
     * Agrupa varios chunks por petición de embeddings. Actualiza {@code chunksRef[0]} (total de chunks indexados).
     */
    private void appendEmbeddingsForParts(
            List<String> parts,
            String displaySource,
            String ns,
            String userLabel,
            int totalIndexable,
            int filesIndexedSoFar,
            String progressRel,
            Consumer<IngestProgressDto> onProgress,
            List<VectorRecord> batch,
            int[] chunksRef
    ) {
        int embedBatch = Math.max(1, props.getEmbedChunkBatchSize());
        int totalParts = parts.size();
        if (totalParts > 80) {
            log.warn(
                    "Archivo con muchos fragmentos ({}): {} — Ollama procesará por lotes; la UI puede avanzar lento entre lotes.",
                    totalParts,
                    progressRel);
        }
        for (int start = 0; start < totalParts; start += embedBatch) {
            int end = Math.min(start + embedBatch, totalParts);
            List<String> slice = parts.subList(start, end);
            if (onProgress != null) {
                IngestProgressDto heartbeat = IngestProgressDto.progress(
                        totalIndexable, filesIndexedSoFar, chunksRef[0], progressRel);
                heartbeat.setDetail(
                        "Generando embeddings (lote "
                                + (start + 1)
                                + "–"
                                + end
                                + " de "
                                + totalParts
                                + ")… puede tardar si el archivo es grande.");
                onProgress.accept(heartbeat);
            }
            log.info(
                    "Embeddings ({}): {} textos, archivo {}, fragmentos {}..{} de {}",
                    embeddingClient.getClass().getSimpleName(),
                    slice.size(),
                    progressRel,
                    start + 1,
                    end,
                    totalParts);
            long t0 = System.nanoTime();
            List<float[]> embeddings;
            try {
                embeddings = embeddingClient.embedTexts(slice);
            } catch (RuntimeException e) {
                log.error(
                        "embedTexts falló: archivo={}, fragmentos {}..{}/{}, batchEmbeds={}",
                        progressRel,
                        start + 1,
                        end,
                        totalParts,
                        embedBatch,
                        e);
                throw e;
            }
            long embedMs = (System.nanoTime() - t0) / 1_000_000L;
            log.info(
                    "Embeddings listos en {} ms ({} vectores, cliente={})",
                    embedMs,
                    embeddings.size(),
                    embeddingClient.getClass().getSimpleName());
            if (embeddings.size() != slice.size()) {
                log.error(
                        "Conteo de embeddings incorrecto: esperados {} vectores, obtuve {} (archivo={})",
                        slice.size(),
                        embeddings.size(),
                        progressRel);
                throw new IllegalStateException(
                        "Embedding: esperados " + slice.size() + " vectores, obtuve " + embeddings.size());
            }
            for (int j = 0; j < embeddings.size(); j++) {
                int chunkIdx = start + j;
                float[] v = embeddings.get(j);
                if (v != null && v.length != props.getEmbeddingDimensions()) {
                    log.error(
                            "Dimensión de vector inesperada: {} != docviz.vector.embedding-dimensions={} (archivo={}, chunk {})",
                            v.length,
                            props.getEmbeddingDimensions(),
                            progressRel,
                            chunkIdx);
                }
                // id solo UUID: ns + ":" + uuid superaba VARCHAR(128) con namespaces largos y el INSERT fallaba sin log claro.
                String id = UUID.randomUUID().toString();
                batch.add(new VectorRecord(id, v, displaySource, chunkIdx, userLabel));
                chunksRef[0]++;
                int oneBased = chunkIdx + 1;
                if (onProgress != null && shouldEmitChunkProgress(oneBased, totalParts)) {
                    onProgress.accept(
                            IngestProgressDto.progress(totalIndexable, filesIndexedSoFar, chunksRef[0], progressRel));
                }
                if (batch.size() >= 16) {
                    flushVectorBatch(ns, batch);
                }
            }
            if (onProgress != null) {
                IngestProgressDto afterBatch =
                        IngestProgressDto.progress(totalIndexable, filesIndexedSoFar, chunksRef[0], progressRel);
                afterBatch.setDetail(
                        "Embeddings listos: fragmentos "
                                + (start + 1)
                                + "–"
                                + end
                                + " de "
                                + totalParts
                                + " ("
                                + embedMs
                                + " ms)");
                onProgress.accept(afterBatch);
            }
        }
    }

    /**
     * Descarga en segundo plano los siguientes {@link #PREFETCH_AHEAD} blobs al {@link FileContentCache}
     * (caché acotada por MB total + expulsión por peso; precarga acotada por {@link #PREFETCH_AHEAD}).
     */
    private void submitPrefetchAhead(
            List<String> indexable,
            int currentIndex,
            Path root,
            String rev,
            FileContentCache cache,
            ExecutorService pool,
            boolean ephemeralManagedClone
    ) {
        for (int k = 1; k <= PREFETCH_AHEAD; k++) {
            int idx = currentIndex + k;
            if (idx >= indexable.size()) {
                break;
            }
            String rel = indexable.get(idx);
            pool.submit(() -> prefetchBlobIfAbsent(rel, root, rev, cache, ephemeralManagedClone));
        }
    }

    /** Emite progreso por chunk en los primeros 80; luego cada 10 para no inundar NDJSON. */
    private static boolean shouldEmitChunkProgress(int oneBasedChunkIndex, int totalParts) {
        if (totalParts <= 80) {
            return true;
        }
        return oneBasedChunkIndex <= 80 || oneBasedChunkIndex % 10 == 0 || oneBasedChunkIndex == totalParts;
    }

    private void prefetchBlobIfAbsent(String rel, Path root, String rev, FileContentCache cache, boolean ephemeralManagedClone) {
        try {
            if (cache.get(rel) != null) {
                return;
            }
            long size = gitRepositoryService.objectSizeBytes(root, rev, rel);
            if (size > FileContentCache.MAX_SINGLE_FILE_BYTES) {
                return;
            }
            byte[] raw = gitRepositoryService.materializeAndReadBytes(root, rev, rel);
            cache.put(rel, raw);
            if (ephemeralManagedClone) {
                gitRepositoryService.deleteMaterializedFileIfPresent(root, rel);
            }
        } catch (RuntimeException ignored) {
            // el hilo principal reintenta lectura
        }
    }

    /**
     * Rutas indexables en repos Git: código, texto y documentación legible.
     * Incluye Markdown ({@code .md}, {@code .mdx}, {@code .markdown}) y PDF (texto extraído con PDFBox).
     * Quedan fuera Office (.doc/.docx), imágenes, jars, bytecode, etc.
     */
    private static boolean isIndexablePath(String rel) {
        if (rel == null || rel.isBlank()) {
            return false;
        }
        rel = rel.trim().replace('\\', '/');
        String lower = rel.toLowerCase(Locale.ROOT);
        int slash = Math.max(lower.lastIndexOf('/'), lower.lastIndexOf('\\'));
        String base = (slash >= 0 ? lower.substring(slash + 1) : lower).strip();
        if (base.equals("dockerfile")
                || base.equals("makefile")
                || base.equals("jenkinsfile")
                || base.equals("rakefile")
                || base.equals("gemfile")
                || base.equals(".gitignore")
                || base.equals(".gitattributes")
                || base.equals(".dockerignore")
                || base.equals("readme")) {
            return true;
        }
        return lower.endsWith(".gitattributes")
                || lower.endsWith(".gitmodules")
                || lower.endsWith(".java")
                || lower.endsWith(".kt")
                || lower.endsWith(".kts")
                || lower.endsWith(".xml")
                || lower.endsWith(".properties")
                || lower.endsWith(".yml")
                || lower.endsWith(".yaml")
                || lower.endsWith(".json")
                || lower.endsWith(".jsonc")
                || lower.endsWith(".md")
                || lower.endsWith(".mdx")
                || lower.endsWith(".markdown")
                || lower.endsWith(".pdf")
                || lower.endsWith(".txt")
                || lower.endsWith(".sql")
                || lower.endsWith(".ddl")
                || lower.endsWith(".hql")
                || lower.endsWith(".cql")
                || lower.endsWith(".kql")
                || lower.endsWith(".pgsql")
                || lower.endsWith(".psql")
                || lower.endsWith(".mysql")
                || lower.endsWith(".prc")
                || lower.endsWith(".fnc")
                || lower.endsWith(".pks")
                || lower.endsWith(".tab")
                || lower.endsWith(".vw")
                || lower.endsWith(".gradle")
                || lower.endsWith(".ts")
                || lower.endsWith(".tsx")
                || lower.endsWith(".mts")
                || lower.endsWith(".cts")
                || lower.endsWith(".js")
                || lower.endsWith(".jsx")
                || lower.endsWith(".mjs")
                || lower.endsWith(".cjs")
                || lower.endsWith(".html")
                || lower.endsWith(".htm")
                || lower.endsWith(".css")
                || lower.endsWith(".scss")
                || lower.endsWith(".sass")
                || lower.endsWith(".less")
                || lower.endsWith(".vue")
                || lower.endsWith(".svelte")
                || lower.endsWith(".cob")
                || lower.endsWith(".cpy")
                || lower.endsWith(".cbl")
                // JVM / Android
                || lower.endsWith(".groovy")
                || lower.endsWith(".scala")
                || lower.endsWith(".clj")
                || lower.endsWith(".cljs")
                || lower.endsWith(".jsp")
                || lower.endsWith(".jspf")
                || lower.endsWith(".tag")
                // Go, Rust, Zig, etc.
                || lower.endsWith(".go")
                || lower.endsWith(".mod")
                || lower.endsWith(".sum")
                || lower.endsWith(".rs")
                || lower.endsWith(".zig")
                // C / C++
                || lower.endsWith(".c")
                || lower.endsWith(".h")
                || lower.endsWith(".cc")
                || lower.endsWith(".cpp")
                || lower.endsWith(".cxx")
                || lower.endsWith(".hpp")
                || lower.endsWith(".hh")
                // Python, Ruby, PHP, etc.
                || lower.endsWith(".py")
                || lower.endsWith(".pyi")
                || lower.endsWith(".pyw")
                || lower.endsWith(".pyx")
                || lower.endsWith(".pxd")
                || lower.endsWith(".ipynb")
                || lower.endsWith(".jinja")
                || lower.endsWith(".j2")
                || lower.endsWith(".rb")
                || lower.endsWith(".erb")
                || lower.endsWith(".php")
                // .NET
                || lower.endsWith(".cs")
                || lower.endsWith(".fs")
                || lower.endsWith(".vb")
                // Swift / ObjC
                || lower.endsWith(".swift")
                || lower.endsWith(".m")
                || lower.endsWith(".mm")
                // Shell / scripts
                || lower.endsWith(".sh")
                || lower.endsWith(".bash")
                || lower.endsWith(".zsh")
                || lower.endsWith(".ps1")
                || lower.endsWith(".psm1")
                || lower.endsWith(".bat")
                || lower.endsWith(".cmd")
                // Config / datos
                || lower.endsWith(".toml")
                || lower.endsWith(".ini")
                || lower.endsWith(".cfg")
                || lower.endsWith(".editorconfig")
                || lower.endsWith(".env.example")
                || lower.endsWith(".graphql")
                || lower.endsWith(".gql")
                || lower.endsWith(".proto")
                || lower.endsWith(".rst")
                || lower.endsWith(".adoc")
                || lower.endsWith(".asciidoc")
                || lower.endsWith(".edn")
                // Otros lenguajes frecuentes en monorepos
                || lower.endsWith(".dart")
                || lower.endsWith(".elm")
                || lower.endsWith(".ex")
                || lower.endsWith(".exs")
                || lower.endsWith(".erl")
                || lower.endsWith(".hrl")
                || lower.endsWith(".lua")
                || lower.endsWith(".pl")
                || lower.endsWith(".pm")
                || lower.endsWith(".r")
                || lower.endsWith(".nim")
                || lower.endsWith(".jl")
                || lower.endsWith(".v")
                || lower.endsWith(".sol")
                || lower.endsWith(".tf")
                || lower.endsWith(".hcl");
    }
}
