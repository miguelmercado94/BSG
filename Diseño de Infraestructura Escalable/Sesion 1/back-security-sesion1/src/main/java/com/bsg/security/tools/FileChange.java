package com.bsg.security.tools;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonProperty;

import java.util.List;

/**
 * Un cambio sobre un archivo de texto (líneas 1-based en startLine/endLine).
 */
public final class FileChange {

    private final int startLine;
    private final int endLine;
    private final ChangeType type;
    private final List<String> content;

    @JsonCreator
    public FileChange(
            @JsonProperty("startLine") int startLine,
            @JsonProperty("endLine") Integer endLine,
            @JsonProperty("type") ChangeType type,
            @JsonProperty("content") List<String> content) {
        this.startLine = startLine;
        this.type = type == null ? ChangeType.REPLACE : type;
        this.content = content == null ? List.of() : List.copyOf(content);
        this.endLine = endLine != null ? endLine : startLine;
    }

    public int startLine() {
        return startLine;
    }

    public int endLine() {
        return endLine;
    }

    public ChangeType type() {
        return type;
    }

    public List<String> content() {
        return content;
    }
}
