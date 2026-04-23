package com.bsg.docviz.dto;

import jakarta.validation.constraints.NotBlank;

/** POST /vector/work-area/index-file — indexa un archivo ya aceptado (p. ej. {@code pom_V1.xml}) */
public class WorkAreaIndexFileBody {

    @NotBlank
    private String relativePath;

    public String getRelativePath() {
        return relativePath;
    }

    public void setRelativePath(String relativePath) {
        this.relativePath = relativePath;
    }
}
