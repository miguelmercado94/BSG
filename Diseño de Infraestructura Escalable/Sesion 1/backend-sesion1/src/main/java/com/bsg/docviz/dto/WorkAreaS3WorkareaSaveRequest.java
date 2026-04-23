package com.bsg.docviz.dto;

import jakarta.validation.constraints.NotBlank;

/** Cuerpo de POST /vector/work-area/s3-workarea-save — actualiza objeto en bucket workarea y reindexa en pgvector. */
public class WorkAreaS3WorkareaSaveRequest {

    @NotBlank
    private String objectKey;

    @NotBlank
    private String content;

    public String getObjectKey() {
        return objectKey;
    }

    public void setObjectKey(String objectKey) {
        this.objectKey = objectKey;
    }

    public String getContent() {
        return content;
    }

    public void setContent(String content) {
        this.content = content;
    }
}
