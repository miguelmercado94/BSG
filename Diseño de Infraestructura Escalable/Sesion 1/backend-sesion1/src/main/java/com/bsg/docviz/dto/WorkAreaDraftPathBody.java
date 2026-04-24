package com.bsg.docviz.dto;

import jakarta.validation.constraints.NotBlank;

/** POST /vector/work-area/draft/accept */
public class WorkAreaDraftPathBody {

    @NotBlank
    private String draftRelativePath;

    public String getDraftRelativePath() {
        return draftRelativePath;
    }

    public void setDraftRelativePath(String draftRelativePath) {
        this.draftRelativePath = draftRelativePath;
    }
}
