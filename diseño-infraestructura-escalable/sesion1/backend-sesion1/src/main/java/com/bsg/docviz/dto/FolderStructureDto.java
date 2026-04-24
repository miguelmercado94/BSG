package com.bsg.docviz.dto;

import java.util.ArrayList;
import java.util.List;

public class FolderStructureDto {

    private List<String> archivos = new ArrayList<>();
    private List<FolderStructureDto> folders = new ArrayList<>();
    private String folder = "";

    public List<String> getArchivos() {
        return archivos;
    }

    public void setArchivos(List<String> archivos) {
        this.archivos = archivos;
    }

    public List<FolderStructureDto> getFolders() {
        return folders;
    }

    public void setFolders(List<FolderStructureDto> folders) {
        this.folders = folders;
    }

    public String getFolder() {
        return folder;
    }

    public void setFolder(String folder) {
        this.folder = folder;
    }
}
