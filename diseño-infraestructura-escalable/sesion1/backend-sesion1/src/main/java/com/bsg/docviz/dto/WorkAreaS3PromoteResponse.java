package com.bsg.docviz.dto;

/** Respuesta de POST /vector/work-area/s3-borrador-promote — mismo payload que la ingesta + ubicación en workarea. */
public class WorkAreaS3PromoteResponse extends VectorIngestResponse {

    private String workareaBucket;

    private String workareaObjectKey;

    public String getWorkareaBucket() {
        return workareaBucket;
    }

    public void setWorkareaBucket(String workareaBucket) {
        this.workareaBucket = workareaBucket;
    }

    public String getWorkareaObjectKey() {
        return workareaObjectKey;
    }

    public void setWorkareaObjectKey(String workareaObjectKey) {
        this.workareaObjectKey = workareaObjectKey;
    }
}
