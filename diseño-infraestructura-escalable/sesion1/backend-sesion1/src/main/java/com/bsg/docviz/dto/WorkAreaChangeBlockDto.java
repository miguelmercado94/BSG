package com.bsg.docviz.dto;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonProperty;

import java.util.List;

/**
 * Hunk de cambio anclado por contexto (sin números de línea absolutos), alineado con parches estilo Git.
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
public class WorkAreaChangeBlockDto {

    private String id;
    private String type;

    @JsonProperty("context_before")
    private List<String> contextBefore;

    private List<String> original;

    private List<String> replacement;

    @JsonProperty("context_after")
    private List<String> contextAfter;

    /** Solo para {@code type=create_file}: ruta relativa del archivo nuevo. */
    private String path;

    /** Solo para {@code type=create_file}: líneas del archivo completo. */
    private List<String> content;

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getType() {
        return type;
    }

    public void setType(String type) {
        this.type = type;
    }

    public List<String> getContextBefore() {
        return contextBefore;
    }

    public void setContextBefore(List<String> contextBefore) {
        this.contextBefore = contextBefore;
    }

    public List<String> getOriginal() {
        return original;
    }

    public void setOriginal(List<String> original) {
        this.original = original;
    }

    public List<String> getReplacement() {
        return replacement;
    }

    public void setReplacement(List<String> replacement) {
        this.replacement = replacement;
    }

    public List<String> getContextAfter() {
        return contextAfter;
    }

    public void setContextAfter(List<String> contextAfter) {
        this.contextAfter = contextAfter;
    }

    public String getPath() {
        return path;
    }

    public void setPath(String path) {
        this.path = path;
    }

    public List<String> getContent() {
        return content;
    }

    public void setContent(List<String> content) {
        this.content = content;
    }
}
