package com.bsg.docviz.dto;

public class ConnectResponse {

    private String usuario;
    private boolean connected;
    private String repositoryRoot;
    private FolderStructureDto directory;

    public String getUsuario() {
        return usuario;
    }

    public void setUsuario(String usuario) {
        this.usuario = usuario;
    }

    public boolean isConnected() {
        return connected;
    }

    public void setConnected(boolean connected) {
        this.connected = connected;
    }

    public String getRepositoryRoot() {
        return repositoryRoot;
    }

    public void setRepositoryRoot(String repositoryRoot) {
        this.repositoryRoot = repositoryRoot;
    }

    public FolderStructureDto getDirectory() {
        return directory;
    }

    public void setDirectory(FolderStructureDto directory) {
        this.directory = directory;
    }
}
