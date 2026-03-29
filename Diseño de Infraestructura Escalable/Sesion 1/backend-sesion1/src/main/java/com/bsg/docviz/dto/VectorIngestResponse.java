package com.bsg.docviz.dto;

import java.util.List;

public class VectorIngestResponse {

    private int filesProcessed;
    private int chunksIndexed;
    private List<String> skipped;
    private String namespace;

    public int getFilesProcessed() {
        return filesProcessed;
    }

    public void setFilesProcessed(int filesProcessed) {
        this.filesProcessed = filesProcessed;
    }

    public int getChunksIndexed() {
        return chunksIndexed;
    }

    public void setChunksIndexed(int chunksIndexed) {
        this.chunksIndexed = chunksIndexed;
    }

    public List<String> getSkipped() {
        return skipped;
    }

    public void setSkipped(List<String> skipped) {
        this.skipped = skipped;
    }

    public String getNamespace() {
        return namespace;
    }

    public void setNamespace(String namespace) {
        this.namespace = namespace;
    }
}
