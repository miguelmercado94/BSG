package com.bsg.docviz.dto;

import jakarta.validation.constraints.NotNull;

public class GitConnectRequest {

    @NotNull(message = "mode is required")
    private GitConnectionMode mode;
    private String repositoryUrl;
    private String username;
    private String token;
    private String localPath;
    /** Si viene informado (repos de célula), la sesión usa este namespace y un user_label compartido para RAG/índice. */
    private String vectorNamespace;

    public GitConnectionMode getMode() {
        return mode;
    }

    public void setMode(GitConnectionMode mode) {
        this.mode = mode;
    }

    public String getRepositoryUrl() {
        return repositoryUrl;
    }

    public void setRepositoryUrl(String repositoryUrl) {
        this.repositoryUrl = repositoryUrl;
    }

    public String getUsername() {
        return username;
    }

    public void setUsername(String username) {
        this.username = username;
    }

    public String getToken() {
        return token;
    }

    public void setToken(String token) {
        this.token = token;
    }

    public String getLocalPath() {
        return localPath;
    }

    public void setLocalPath(String localPath) {
        this.localPath = localPath;
    }

    public String getVectorNamespace() {
        return vectorNamespace;
    }

    public void setVectorNamespace(String vectorNamespace) {
        this.vectorNamespace = vectorNamespace;
    }
}
