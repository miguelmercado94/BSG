package com.bsg.docviz.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

/** POST /vector/work-area/draft/finalize — texto UTF-8 ya resuelto (p. ej. desde la vista de conflictos). */
public class WorkAreaDraftFinalizeBody {

    @NotBlank
    private String draftRelativePath;

    @NotNull
    private String finalContent;

    public String getDraftRelativePath() {
        return draftRelativePath;
    }

    public void setDraftRelativePath(String draftRelativePath) {
        this.draftRelativePath = draftRelativePath;
    }

    public String getFinalContent() {
        return finalContent;
    }

    public void setFinalContent(String finalContent) {
        this.finalContent = finalContent;
    }
}
