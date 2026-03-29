package com.bsg.docviz.vector;

import com.bsg.docviz.config.VectorProperties;
import com.bsg.docviz.dto.VectorIngestResponse;
import com.bsg.docviz.security.CurrentUser;
import com.bsg.docviz.security.UserIdSanitizer;
import com.bsg.docviz.service.GitRepositoryService;
import com.bsg.docviz.service.SessionRegistry;
import com.bsg.docviz.util.SourceTextExtractor;
import com.bsg.docviz.util.TextChunker;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.UUID;

@Service
public class VectorIngestService {

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
        Path root = s.getRepositoryRoot();
        String user = UserIdSanitizer.forFilesystem(CurrentUser.require());
        String label = s.getRootFolderLabel() != null ? s.getRootFolderLabel() : "repo";
        return user + "__" + label.replaceAll("[^a-zA-Z0-9._-]", "_");
    }

    public VectorIngestResponse ingestAll() {
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

        int files = 0;
        int chunks = 0;
        List<String> skipped = new ArrayList<>();
        List<PineconeVectorClient.VectorRecord> batch = new ArrayList<>();

        for (String rel : paths) {
            if (!isIndexablePath(rel)) {
                skipped.add(rel + " (tipo no indexable)");
                continue;
            }
            try {
                long size = gitRepositoryService.objectSizeBytes(root, rev, rel);
                if (size > com.bsg.docviz.service.FileContentCache.MAX_TOTAL_BYTES) {
                    skipped.add(rel + " (muy grande)");
                    continue;
                }
                byte[] raw = gitRepositoryService.readBlob(root, rev, rel);
                String text = SourceTextExtractor.extractText(rel, raw);
                if (text == null || text.isBlank()) {
                    skipped.add(rel + " (sin texto)");
                    continue;
                }
                List<String> parts = TextChunker.chunk(text, props.getChunkSize(), props.getChunkOverlap());
                String displaySource = session.getRootFolderLabel() + "/" + rel;
                int idx = 0;
                for (String part : parts) {
                    List<float[]> emb = pinecone.embedTexts(List.of(part));
                    float[] v = emb.get(0);
                    String id = ns + ":" + UUID.randomUUID();
                    batch.add(new PineconeVectorClient.VectorRecord(id, v, displaySource, idx, userLabel));
                    idx++;
                    chunks++;
                    if (batch.size() >= 16) {
                        pinecone.upsertBatch(indexHost, ns, batch);
                        batch.clear();
                        sleepDelay();
                    }
                }
                files++;
            } catch (RuntimeException ex) {
                skipped.add(rel + ": " + ex.getMessage());
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
        return r;
    }

    private void sleepDelay() {
        try {
            Thread.sleep(props.getEmbedBatchDelayMs());
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
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
