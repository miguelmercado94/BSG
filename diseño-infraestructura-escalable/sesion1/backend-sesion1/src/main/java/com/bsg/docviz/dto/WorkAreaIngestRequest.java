package com.bsg.docviz.dto;

import jakarta.validation.constraints.NotBlank;

/** Cuerpo de POST /vector/work-area/ingest — indexa texto como fuente virtual bajo &lt;repo&gt;/workarea/&lt;nombre&gt;. */
public class WorkAreaIngestRequest {

    @NotBlank
    private String fileName;

    @NotBlank
    private String content;

    public String getFileName() {
        return fileName;
    }

    public void setFileName(String fileName) {
        this.fileName = fileName;
    }

    public String getContent() {
        return content;
    }

    public void setContent(String content) {
        this.content = content;
    }
}
