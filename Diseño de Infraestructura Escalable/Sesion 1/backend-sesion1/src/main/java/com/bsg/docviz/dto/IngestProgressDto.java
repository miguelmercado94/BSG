package com.bsg.docviz.dto;

import java.util.List;

/**
 * Eventos de progreso de ingesta (NDJSON). Fases: START, FILE, PROGRESS, DONE, ERROR.
 */
public class IngestProgressDto {

    private String phase;
    private Integer totalFiles;
    private Integer filesProcessed;
    private Integer chunksIndexed;
    private String currentFile;
    private String namespace;
    private List<String> skipped;
    private String error;

    public static IngestProgressDto start(int totalFiles) {
        IngestProgressDto d = new IngestProgressDto();
        d.setPhase("START");
        d.setTotalFiles(totalFiles);
        d.setFilesProcessed(0);
        d.setChunksIndexed(0);
        return d;
    }

    public static IngestProgressDto file(int totalFiles, int filesProcessedSoFar, int chunksIndexed, String currentFile) {
        IngestProgressDto d = new IngestProgressDto();
        d.setPhase("FILE");
        d.setTotalFiles(totalFiles);
        d.setFilesProcessed(filesProcessedSoFar);
        d.setChunksIndexed(chunksIndexed);
        d.setCurrentFile(currentFile);
        return d;
    }

    public static IngestProgressDto progress(int totalFiles, int filesProcessed, int chunksIndexed, String lastFile) {
        IngestProgressDto d = new IngestProgressDto();
        d.setPhase("PROGRESS");
        d.setTotalFiles(totalFiles);
        d.setFilesProcessed(filesProcessed);
        d.setChunksIndexed(chunksIndexed);
        d.setCurrentFile(lastFile);
        return d;
    }

    public static IngestProgressDto done(VectorIngestResponse r) {
        IngestProgressDto d = new IngestProgressDto();
        d.setPhase("DONE");
        d.setTotalFiles(null);
        d.setFilesProcessed(r.getFilesProcessed());
        d.setChunksIndexed(r.getChunksIndexed());
        d.setNamespace(r.getNamespace());
        d.setSkipped(r.getSkipped());
        return d;
    }

    public static IngestProgressDto error(String message) {
        IngestProgressDto d = new IngestProgressDto();
        d.setPhase("ERROR");
        d.setError(message);
        return d;
    }

    public String getPhase() {
        return phase;
    }

    public void setPhase(String phase) {
        this.phase = phase;
    }

    public Integer getTotalFiles() {
        return totalFiles;
    }

    public void setTotalFiles(Integer totalFiles) {
        this.totalFiles = totalFiles;
    }

    public Integer getFilesProcessed() {
        return filesProcessed;
    }

    public void setFilesProcessed(Integer filesProcessed) {
        this.filesProcessed = filesProcessed;
    }

    public Integer getChunksIndexed() {
        return chunksIndexed;
    }

    public void setChunksIndexed(Integer chunksIndexed) {
        this.chunksIndexed = chunksIndexed;
    }

    public String getCurrentFile() {
        return currentFile;
    }

    public void setCurrentFile(String currentFile) {
        this.currentFile = currentFile;
    }

    public String getNamespace() {
        return namespace;
    }

    public void setNamespace(String namespace) {
        this.namespace = namespace;
    }

    public List<String> getSkipped() {
        return skipped;
    }

    public void setSkipped(List<String> skipped) {
        this.skipped = skipped;
    }

    public String getError() {
        return error;
    }

    public void setError(String error) {
        this.error = error;
    }
}
