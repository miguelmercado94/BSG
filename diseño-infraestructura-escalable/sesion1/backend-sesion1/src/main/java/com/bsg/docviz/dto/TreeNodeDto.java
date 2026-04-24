package com.bsg.docviz.dto;

import java.util.ArrayList;
import java.util.List;

/** Árbol de paths de archivos trackeados (un nivel = un segmento de ruta). */
public class TreeNodeDto {

    private List<String> archivos = new ArrayList<>();
    private List<TreeNodeDto> folders = new ArrayList<>();
    private String folder = "";

    public List<String> getArchivos() {
        return archivos;
    }

    public void setArchivos(List<String> archivos) {
        this.archivos = archivos;
    }

    public List<TreeNodeDto> getFolders() {
        return folders;
    }

    public void setFolders(List<TreeNodeDto> folders) {
        this.folders = folders;
    }

    public String getFolder() {
        return folder;
    }

    public void setFolder(String folder) {
        this.folder = folder;
    }
}
