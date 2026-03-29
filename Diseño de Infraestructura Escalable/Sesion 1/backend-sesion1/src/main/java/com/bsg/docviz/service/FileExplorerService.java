package com.bsg.docviz.service;

import com.bsg.docviz.dto.FileContentResponse;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.nio.charset.StandardCharsets;
import java.nio.file.Path;

@Service
public class FileExplorerService {

    private final SessionRegistry sessionRegistry;
    private final GitRepositoryService gitRepositoryService;

    public FileExplorerService(SessionRegistry sessionRegistry, GitRepositoryService gitRepositoryService) {
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
        try {
            long size = gitRepositoryService.objectSizeBytes(root, rev, rel);
            if (size > FileContentCache.MAX_TOTAL_BYTES) {
                throw new ResponseStatusException(HttpStatus.PAYLOAD_TOO_LARGE, "file too large");
            }
            byte[] raw = gitRepositoryService.readBlob(root, rev, rel);
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
