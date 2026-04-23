package com.bsg.docviz.dto;

/** Respuesta de POST /support/markdown (subida a S3 + embeddings en pgvector). */
public class SupportMarkdownUploadResponse {

    private String bucket;
    private String objectKey;
    /** Nombre relativo al prefijo S3 del repo/sesión; para DELETE/PUT sin exponer la clave completa. */
    private String fileName;
    /** Valor de {@code source} en pgvector (prefijo {@code soporte:} + objectKey). */
    private String vectorSource;
    private String namespace;
    private int chunksIndexed;

    public String getBucket() {
        return bucket;
    }

    public void setBucket(String bucket) {
        this.bucket = bucket;
    }

    public String getObjectKey() {
        return objectKey;
    }

    public void setObjectKey(String objectKey) {
        this.objectKey = objectKey;
    }

    public String getFileName() {
        return fileName;
    }

    public void setFileName(String fileName) {
        this.fileName = fileName;
    }

    public String getVectorSource() {
        return vectorSource;
    }

    public void setVectorSource(String vectorSource) {
        this.vectorSource = vectorSource;
    }

    public String getNamespace() {
        return namespace;
    }

    public void setNamespace(String namespace) {
        this.namespace = namespace;
    }

    public int getChunksIndexed() {
        return chunksIndexed;
    }

    public void setChunksIndexed(int chunksIndexed) {
        this.chunksIndexed = chunksIndexed;
    }
}
