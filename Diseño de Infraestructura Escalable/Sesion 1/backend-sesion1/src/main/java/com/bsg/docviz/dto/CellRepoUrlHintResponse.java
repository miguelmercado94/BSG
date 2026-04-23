package com.bsg.docviz.dto;

public record CellRepoUrlHintResponse(
        String displayName,
        String vectorNamespace,
        boolean reusedFromExisting,
        /** Rama por defecto del remoto (p. ej. main) o HEAD local; null si no se pudo detectar. */
        String defaultBranch) {}
