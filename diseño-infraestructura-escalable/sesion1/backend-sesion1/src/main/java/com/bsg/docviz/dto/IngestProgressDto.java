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
    /** Mensaje breve opcional (p. ej. mientras Ollama genera embeddings). */
    private String detail;
    private String namespace;
    private List<String> skipped;
    private String error;
    /** Metadatos finales tras crear repo de célula (NDJSON admin). */
    private Long cellRepoId;
    private String displayName;
    private Boolean linkedWithoutReindex;

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

    /**
     * Último evento del stream {@code POST /admin/cells/{id}/repos/stream}: fila persistida y stats finales.
     * Si acaba de ejecutarse una ingesta, pasar {@code justIngested} para que el NDJSON lleve los mismos
     * conteos que {@link #done(VectorIngestResponse)} aunque el {@link CellRepoResponse} leído de BD aún no
     * refleje {@code last_ingest_*} (p. ej. lectura desfasada o mapeo).
     */
    public static IngestProgressDto cellRepoReady(CellRepoResponse r) {
        return cellRepoReady(r, null);
    }

    public static IngestProgressDto cellRepoReady(CellRepoResponse r, VectorIngestResponse justIngested) {
        IngestProgressDto d = new IngestProgressDto();
        d.setPhase("CELL_REPO_READY");
        d.setCellRepoId(r.id());
        d.setDisplayName(r.displayName());
        d.setLinkedWithoutReindex(r.linkedWithoutReindex());
        d.setNamespace(r.vectorNamespace());
        if (justIngested != null) {
            d.setFilesProcessed(justIngested.getFilesProcessed());
            d.setChunksIndexed(justIngested.getChunksIndexed());
            d.setSkipped(justIngested.getSkipped() != null ? justIngested.getSkipped() : List.of());
        } else {
            d.setFilesProcessed(r.lastIngestFiles() != null ? r.lastIngestFiles() : 0);
            d.setChunksIndexed(r.lastIngestChunks() != null ? r.lastIngestChunks() : 0);
            d.setSkipped(r.lastIngestSkipped() != null ? r.lastIngestSkipped() : List.of());
        }
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

    public String getDetail() {
        return detail;
    }

    public void setDetail(String detail) {
        this.detail = detail;
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

    public Long getCellRepoId() {
        return cellRepoId;
    }

    public void setCellRepoId(Long cellRepoId) {
        this.cellRepoId = cellRepoId;
    }

    public String getDisplayName() {
        return displayName;
    }

    public void setDisplayName(String displayName) {
        this.displayName = displayName;
    }

    public Boolean getLinkedWithoutReindex() {
        return linkedWithoutReindex;
    }

    public void setLinkedWithoutReindex(Boolean linkedWithoutReindex) {
        this.linkedWithoutReindex = linkedWithoutReindex;
    }
}
