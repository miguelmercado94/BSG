package com.bsg.docviz.vector;

import com.bsg.docviz.config.VectorProperties;
import com.bsg.docviz.dto.IngestProgressDto;
import com.bsg.docviz.dto.VectorIngestResponse;
import com.bsg.docviz.security.CurrentUser;
import com.bsg.docviz.security.UserIdSanitizer;
import com.bsg.docviz.service.FileContentCache;
import com.bsg.docviz.service.GitRepositoryService;
import com.bsg.docviz.service.SessionRegistry;
import com.bsg.docviz.util.SourceTextExtractor;
import com.bsg.docviz.util.TextChunker;
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

    /** Archivos a precargar por delante del actual (pila/cola acotada: 1 actual + 4 prefetch = 5). */
    private static final int PREFETCH_AHEAD = 4;

    private final VectorProperties props;
    private final PineconeVectorClient pinecone;
    private final GitRepositoryService gitRepositoryService;
    private final SessionRegistry sessionRegistry;

    public VectorIngestService(
            VectorProperties props,
            PineconeVectorClient pinecone,
            GitRepositoryService gitRepositoryService,
            SessionRegistry sessionRegistry
    ) {
        this.props = props;
        this.pinecone = pinecone;
        this.gitRepositoryService = gitRepositoryService;
        this.sessionRegistry = sessionRegistry;
    }

    public String currentNamespace() {
        var s = sessionRegistry.current();
        String user = UserIdSanitizer.forFilesystem(CurrentUser.require());
        String label = s.getRootFolderLabel() != null ? s.getRootFolderLabel() : "repo";
        return user + "__" + label.replaceAll("[^a-zA-Z0-9._-]", "_");
    }

    public VectorIngestResponse ingestAll() {
        return ingestAll(null);
    }

    /**
     * Ingesta con eventos de progreso (START, FILE, PROGRESS por archivo indexado, DONE).
     * Si {@code onProgress} es null, no se emiten eventos.
     */
    public VectorIngestResponse ingestAll(Consumer<IngestProgressDto> onProgress) {
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
        String ns = currentNamespace();
        String indexHost = pinecone.getIndexHost();
        String userLabel = CurrentUser.require().trim();

        List<String> paths;
        try {
            paths = gitRepositoryService.listTrackedFiles(root, rev);
        } catch (Exception e) {
            throw new IllegalStateException("Cannot list files: " + e.getMessage(), e);
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
        if (onProgress != null) {
            onProgress.accept(IngestProgressDto.start(totalIndexable));
        }

        int files = 0;
        int chunks = 0;
        List<PineconeVectorClient.VectorRecord> batch = new ArrayList<>();

        ExecutorService prefetchPool = props.isPrefetchUsePlatformThreads()
                ? Executors.newFixedThreadPool(Math.min(PREFETCH_AHEAD, 4))
                : Executors.newVirtualThreadPerTaskExecutor();
        try {
            for (int i = 0; i < indexable.size(); i++) {
                String rel = indexable.get(i);
                submitPrefetchAhead(indexable, i, root, rev, blobCache, prefetchPool, session.isEphemeralManagedClone());
                if (onProgress != null) {
                    onProgress.accept(IngestProgressDto.file(totalIndexable, files, chunks, rel));
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
                    String displaySource = session.getRootFolderLabel() + "/" + rel;
                    int[] chunksRef = new int[] {chunks};
                    appendEmbeddingsForParts(
                            parts,
                            displaySource,
                            ns,
                            indexHost,
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
            pinecone.upsertBatch(indexHost, ns, batch);
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
        String indexHost = pinecone.getIndexHost();
        String userLabel = CurrentUser.require().trim();
        String displaySource = "classpath:" + resourcePath;
        int totalIndexable = 1;
        List<String> skipped = new ArrayList<>();

        if (onProgress != null) {
            onProgress.accept(IngestProgressDto.start(totalIndexable));
        }
        if (onProgress != null) {
            onProgress.accept(IngestProgressDto.file(totalIndexable, 0, 0, resourcePath));
        }

        List<String> parts = TextChunker.chunk(text, props.getChunkSize(), props.getChunkOverlap());
        List<PineconeVectorClient.VectorRecord> batch = new ArrayList<>();
        int files = 0;
        int chunks = 0;
        int[] chunksRef = new int[] {0};
        appendEmbeddingsForParts(
                parts,
                displaySource,
                ns,
                indexHost,
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
            pinecone.upsertBatch(indexHost, ns, batch);
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

    private void sleepDelay() {
        try {
            Thread.sleep(props.getEmbedBatchDelayMs());
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }

    /**
     * Agrupa varios chunks por petición HTTP a Pinecone {@code /embed}. Actualiza {@code chunksRef[0]} (total de chunks indexados).
     */
    private void appendEmbeddingsForParts(
            List<String> parts,
            String displaySource,
            String ns,
            String indexHost,
            String userLabel,
            int totalIndexable,
            int filesIndexedSoFar,
            String progressRel,
            Consumer<IngestProgressDto> onProgress,
            List<PineconeVectorClient.VectorRecord> batch,
            int[] chunksRef
    ) {
        int embedBatch = Math.max(1, props.getEmbedChunkBatchSize());
        int totalParts = parts.size();
        for (int start = 0; start < totalParts; start += embedBatch) {
            int end = Math.min(start + embedBatch, totalParts);
            List<String> slice = parts.subList(start, end);
            List<float[]> embeddings = pinecone.embedTexts(slice);
            if (embeddings.size() != slice.size()) {
                throw new IllegalStateException(
                        "Pinecone embed: esperados " + slice.size() + " vectores, obtuve " + embeddings.size());
            }
            for (int j = 0; j < embeddings.size(); j++) {
                int chunkIdx = start + j;
                float[] v = embeddings.get(j);
                String id = ns + ":" + UUID.randomUUID();
                batch.add(new PineconeVectorClient.VectorRecord(id, v, displaySource, chunkIdx, userLabel));
                chunksRef[0]++;
                int oneBased = chunkIdx + 1;
                if (onProgress != null && shouldEmitChunkProgress(oneBased, totalParts)) {
                    onProgress.accept(
                            IngestProgressDto.progress(totalIndexable, filesIndexedSoFar, chunksRef[0], progressRel));
                }
                if (batch.size() >= 16) {
                    pinecone.upsertBatch(indexHost, ns, batch);
                    batch.clear();
                    sleepDelay();
                }
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

    private static boolean isIndexablePath(String rel) {
        String lower = rel.toLowerCase(Locale.ROOT);
        return lower.endsWith(".java") || lower.endsWith(".kt") || lower.endsWith(".xml")
                || lower.endsWith(".properties") || lower.endsWith(".yml") || lower.endsWith(".yaml")
                || lower.endsWith(".json") || lower.endsWith(".md") || lower.endsWith(".txt")
                || lower.endsWith(".sql") || lower.endsWith(".gradle") || lower.endsWith(".pdf")
                || lower.endsWith(".ts") || lower.endsWith(".tsx") || lower.endsWith(".js") || lower.endsWith(".jsx")
                || lower.endsWith(".html") || lower.endsWith(".css") || lower.endsWith(".cob");
    }
}
