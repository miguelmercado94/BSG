package com.bsg.security.tools;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonProperty;

import java.util.List;

/**
 * Contenedor opcional para deserializar {@code { "changes": [ ... ] }}.
 */
public final class ChangesPayload {

    private final List<FileChange> changes;

    @JsonCreator
    public ChangesPayload(@JsonProperty("changes") List<FileChange> changes) {
        this.changes = changes == null ? List.of() : List.copyOf(changes);
    }

    public List<FileChange> changes() {
        return changes;
    }
}
