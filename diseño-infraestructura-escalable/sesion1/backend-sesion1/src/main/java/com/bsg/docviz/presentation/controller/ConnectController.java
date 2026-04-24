package com.bsg.docviz.presentation.controller;

import com.bsg.docviz.dto.ConnectResponse;
import com.bsg.docviz.dto.FolderStructureDto;
import com.bsg.docviz.dto.FolderStructureMapper;
import com.bsg.docviz.dto.GitConnectRequest;
import com.bsg.docviz.security.CurrentUser;
import com.bsg.docviz.application.port.output.GitRepositoryPort;
import com.bsg.docviz.application.port.output.SessionRegistryPort;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class ConnectController {

    private final GitRepositoryPort gitRepositoryService;
    private final SessionRegistryPort sessionRegistry;

    public ConnectController(GitRepositoryPort gitRepositoryService, SessionRegistryPort sessionRegistry) {
        this.gitRepositoryService = gitRepositoryService;
        this.sessionRegistry = sessionRegistry;
    }

    @PostMapping("/connect/git")
    public ResponseEntity<ConnectResponse> connect(@Valid @RequestBody GitConnectRequest body) {
        gitRepositoryService.connect(body);
        var session = sessionRegistry.current();
        var root = session.getRepositoryRoot();
        var tree = session.getTreeRoot();
        FolderStructureDto directory = FolderStructureMapper.fromTreeRoot(tree, session.getRootFolderLabel(), root);
        FolderStructureMapper.ensureRootFolderName(directory, root);
        if (directory != null) {
            String name = extractRepoName(body.getRepositoryUrl());
            if (!name.isBlank()) {
                directory.setFolder(name);
            }
        }
        String repositoryRootStr = root == null ? null : root.toString();
        ConnectResponse res = new ConnectResponse();
        res.setUsuario(CurrentUser.require());
        res.setConnected(true);
        res.setRepositoryRoot(repositoryRootStr);
        res.setDirectory(directory);
        return ResponseEntity.ok(res);
    }

    private static String extractRepoName(String url) {
        if (url == null || url.isBlank()) {
            return "";
        }
        String name = url.substring(url.lastIndexOf("/") + 1);
        return name.endsWith(".git") ? name.substring(0, name.length() - 4) : name;
    }
}
