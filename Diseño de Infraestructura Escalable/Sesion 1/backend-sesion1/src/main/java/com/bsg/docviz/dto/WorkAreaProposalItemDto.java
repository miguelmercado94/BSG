package com.bsg.docviz.dto;

import com.fasterxml.jackson.annotation.JsonInclude;

import java.util.List;

@JsonInclude(JsonInclude.Include.NON_NULL)
public class WorkAreaProposalItemDto {

    private String id;
    private String fileName;
    private String extension;
    private String content;
    private String sourcePath;
    /** Borrador en disco: {@code ruta/pom_V1.xml.txt} (merge estilo Git). Opcional si solo hay JSON en memoria. */
    private String draftRelativePath;
    /** Versión N usada en {@code *_vN.*}; necesaria para aplicar sin .txt. */
    private Integer draftVersion;
    /**
     * Sustituciones por rango (líneas 1-based del archivo en {@link #sourcePath}). Preferible en archivos grandes
     * frente a reescribir {@link #content} o listas largas de {@link #diffLines}.
     */
    /**
     * Hunks anclados por contexto (sin números de línea); ver {@link WorkAreaChangeBlockDto}.
     */
    private List<WorkAreaChangeBlockDto> changeBlocks;
    private List<WorkAreaLineEditDto> lineEdits;
    private List<WorkAreaDiffLineDto> diffLines;

    /**
     * Propuesta parseada desde YAML del modelo; el servidor la traduce a borrador estándar DocViz. Se limpia tras
     * enriquecer para no ampliar el contrato REST/WebSocket.
     */
    private List<WorkAreaYamlProposalBlockDto> yamlBlocks;
    /** REPO o LOCAL (solo si vino del YAML de path con prefijo). */
    private String proposalOriginKind;
    private String localS3Bucket;
    private String localS3ObjectKey;
    /** Solo YAML: {@code new: true} si el archivo aún no existe en REPO. */
    private Boolean yamlNewFile;

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getFileName() {
        return fileName;
    }

    public void setFileName(String fileName) {
        this.fileName = fileName;
    }

    public String getExtension() {
        return extension;
    }

    public void setExtension(String extension) {
        this.extension = extension;
    }

    public String getContent() {
        return content;
    }

    public void setContent(String content) {
        this.content = content;
    }

    public String getSourcePath() {
        return sourcePath;
    }

    public void setSourcePath(String sourcePath) {
        this.sourcePath = sourcePath;
    }

    public String getDraftRelativePath() {
        return draftRelativePath;
    }

    public void setDraftRelativePath(String draftRelativePath) {
        this.draftRelativePath = draftRelativePath;
    }

    public Integer getDraftVersion() {
        return draftVersion;
    }

    public void setDraftVersion(Integer draftVersion) {
        this.draftVersion = draftVersion;
    }

    public List<WorkAreaLineEditDto> getLineEdits() {
        return lineEdits;
    }

    public void setLineEdits(List<WorkAreaLineEditDto> lineEdits) {
        this.lineEdits = lineEdits;
    }

    public List<WorkAreaChangeBlockDto> getChangeBlocks() {
        return changeBlocks;
    }

    public void setChangeBlocks(List<WorkAreaChangeBlockDto> changeBlocks) {
        this.changeBlocks = changeBlocks;
    }

    public List<WorkAreaDiffLineDto> getDiffLines() {
        return diffLines;
    }

    public void setDiffLines(List<WorkAreaDiffLineDto> diffLines) {
        this.diffLines = diffLines;
    }

    public List<WorkAreaYamlProposalBlockDto> getYamlBlocks() {
        return yamlBlocks;
    }

    public void setYamlBlocks(List<WorkAreaYamlProposalBlockDto> yamlBlocks) {
        this.yamlBlocks = yamlBlocks;
    }

    public String getProposalOriginKind() {
        return proposalOriginKind;
    }

    public void setProposalOriginKind(String proposalOriginKind) {
        this.proposalOriginKind = proposalOriginKind;
    }

    public String getLocalS3Bucket() {
        return localS3Bucket;
    }

    public void setLocalS3Bucket(String localS3Bucket) {
        this.localS3Bucket = localS3Bucket;
    }

    public String getLocalS3ObjectKey() {
        return localS3ObjectKey;
    }

    public void setLocalS3ObjectKey(String localS3ObjectKey) {
        this.localS3ObjectKey = localS3ObjectKey;
    }

    public Boolean getYamlNewFile() {
        return yamlNewFile;
    }

    public void setYamlNewFile(Boolean yamlNewFile) {
        this.yamlNewFile = yamlNewFile;
    }
}
