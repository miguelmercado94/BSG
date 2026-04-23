package com.bsg.docviz.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

/** POST /vector/work-area/apply-final — contenido ya resuelto (p. ej. vista merge de un solo bloque). */
public class WorkAreaApplyFinalBody {

    @NotBlank
    private String sourcePath;

    @NotNull
    private Integer draftVersion;

    @NotBlank
    private String finalContent;

    public String getSourcePath() {
        return sourcePath;
    }

    public void setSourcePath(String sourcePath) {
        this.sourcePath = sourcePath;
    }

    public Integer getDraftVersion() {
        return draftVersion;
    }

    public void setDraftVersion(Integer draftVersion) {
        this.draftVersion = draftVersion;
    }

    public String getFinalContent() {
        return finalContent;
    }

    public void setFinalContent(String finalContent) {
        this.finalContent = finalContent;
    }
}
