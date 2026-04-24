package com.bsg.docviz.service;

import com.bsg.docviz.application.port.output.FileExplorerPort;
import com.bsg.docviz.application.port.output.GitRepositoryPort;
import com.bsg.docviz.application.port.output.SessionRegistryPort;
import com.bsg.docviz.dto.FileContentResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.nio.charset.StandardCharsets;
import java.nio.file.Path;

@Service
public class FileExplorerService implements FileExplorerPort {

    private static final Logger log = LoggerFactory.getLogger(FileExplorerService.class);

    private final SessionRegistryPort sessionRegistry;
    private final GitRepositoryPort gitRepositoryService;

    public FileExplorerService(SessionRegistryPort sessionRegistry, GitRepositoryPort gitRepositoryService) {
        this.sessionRegistry = sessionRegistry;
        this.gitRepositoryService = gitRepositoryService;
    }

    public FileContentResponse readFile(String queryPath) {
        var session = sessionRegistry.current();
        if (!session.isConnected()) {
            throw new IllegalStateException("Not connected to a repository");
        }
        Path root = session.getRepositoryRoot();
        if (root == null) {
            throw new IllegalStateException("Not connected to a repository");
        }
        String rel = queryPath == null ? "" : queryPath.trim();
        if (rel.isBlank()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "query path required");
        }
        String rev = session.getRevisionSpec();
        FileContentCache cache = session.getViewerContentCache();
        try {
            byte[] raw = cache.get(rel);
            if (raw != null) {
                log.debug("readFile: caché hit rel={} rev={} bytes={}", rel, rev, raw.length);
                FileContentResponse hit = new FileContentResponse();
                hit.setPath(rel);
                hit.setEncoding("utf-8");
                hit.setContent(new String(raw, StandardCharsets.UTF_8));
                return hit;
            }
            long size = gitRepositoryService.objectSizeBytes(root, rev, rel);
            log.debug("readFile: blob rel={} rev={} sizeBytes={}", rel, rev, size);
            if (size > FileContentCache.MAX_SINGLE_FILE_BYTES) {
                throw new ResponseStatusException(HttpStatus.PAYLOAD_TOO_LARGE, "file too large");
            }
            raw = gitRepositoryService.materializeAndReadBytes(root, rev, rel);
            log.debug(
                    "readFile: materializado y leído rel={} rev={} bytes={} ephemeralClone={}",
                    rel,
                    rev,
                    raw.length,
                    session.isEphemeralManagedClone());
            cache.put(rel, raw);
            if (session.isEphemeralManagedClone()) {
                gitRepositoryService.deleteMaterializedFileIfPresent(root, rel);
            }
            FileContentResponse r = new FileContentResponse();
            r.setPath(rel);
            r.setEncoding("utf-8");
            r.setContent(new String(raw, StandardCharsets.UTF_8));
            return r;
        } catch (RuntimeException e) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, e.getMessage());
        }
    }
}
