package com.bsg.docviz.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "docviz.vector")
public class VectorProperties {

    private boolean enabled = true;
    private String pineconeApiKey = "";
    private String pineconeIndexName = "docviz-embed";
    private String pineconeIndexHost = "";
    private String pineconeEmbedModel = "llama-text-embed-v2";
    private long embedBatchDelayMs = 2500;
    private int chunkSize = 800;
    private int chunkOverlap = 120;
    private int ragTopK = 6;

    public boolean isEnabled() {
        return enabled;
    }

    public void setEnabled(boolean enabled) {
        this.enabled = enabled;
    }

    public String getPineconeApiKey() {
        return pineconeApiKey;
    }

    public void setPineconeApiKey(String pineconeApiKey) {
        this.pineconeApiKey = pineconeApiKey;
    }

    public String getPineconeIndexName() {
        return pineconeIndexName;
    }

    public void setPineconeIndexName(String pineconeIndexName) {
        this.pineconeIndexName = pineconeIndexName;
    }

    public String getPineconeIndexHost() {
        return pineconeIndexHost;
    }

    public void setPineconeIndexHost(String pineconeIndexHost) {
        this.pineconeIndexHost = pineconeIndexHost;
    }

    public String getPineconeEmbedModel() {
        return pineconeEmbedModel;
    }

    public void setPineconeEmbedModel(String pineconeEmbedModel) {
        this.pineconeEmbedModel = pineconeEmbedModel;
    }

    public long getEmbedBatchDelayMs() {
        return embedBatchDelayMs;
    }

    public void setEmbedBatchDelayMs(long embedBatchDelayMs) {
        this.embedBatchDelayMs = embedBatchDelayMs;
    }

    public int getChunkSize() {
        return chunkSize;
    }

    public void setChunkSize(int chunkSize) {
        this.chunkSize = chunkSize;
    }

    public int getChunkOverlap() {
        return chunkOverlap;
    }

    public void setChunkOverlap(int chunkOverlap) {
        this.chunkOverlap = chunkOverlap;
    }

    public int getRagTopK() {
        return ragTopK;
    }

    public void setRagTopK(int ragTopK) {
        this.ragTopK = ragTopK;
    }
}
