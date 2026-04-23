package com.bsg.docviz.dto;

import jakarta.validation.constraints.NotEmpty;

import java.util.List;

/** POST /vector/work-area/draft/accept-all */
public class WorkAreaDraftAcceptAllBody {

    @NotEmpty
    private List<String> draftRelativePaths;

    public List<String> getDraftRelativePaths() {
        return draftRelativePaths;
    }

    public void setDraftRelativePaths(List<String> draftRelativePaths) {
        this.draftRelativePaths = draftRelativePaths;
    }
}
