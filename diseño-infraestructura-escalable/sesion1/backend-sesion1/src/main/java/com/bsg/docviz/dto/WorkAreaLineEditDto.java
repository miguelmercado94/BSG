package com.bsg.docviz.dto;

import com.fasterxml.jackson.annotation.JsonInclude;

/**
 * Sustitución por rango de líneas en el archivo base (numeración 1-based, inclusive).
 * El LLM indica qué líneas del original se sustituyen por {@code replacement} sin reenviar el archivo entero.
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
public class WorkAreaLineEditDto {

    private int startLine;
    private int endLine;
    /** Texto nuevo (puede ser multilínea). Vacío o ausente = borrar el rango. */
    private String replacement;

    public int getStartLine() {
        return startLine;
    }

    public void setStartLine(int startLine) {
        this.startLine = startLine;
    }

    public int getEndLine() {
        return endLine;
    }

    public void setEndLine(int endLine) {
        this.endLine = endLine;
    }

    public String getReplacement() {
        return replacement;
    }

    public void setReplacement(String replacement) {
        this.replacement = replacement;
    }
}
