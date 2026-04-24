package com.bsg.docviz.dto;

import java.time.Instant;
import java.util.List;

public record CellRepoResponse(
        long id,
        /** Null si el repo está indexado pero aún no asignado a una célula (pendiente de “Guardar”). */
        Long cellId,
        String displayName,
        String repositoryUrl,
        GitConnectionMode connectionMode,
        String gitUsername,
        boolean hasCredential,
        String localPath,
        String tagsCsv,
        String vectorNamespace,
        boolean active,
        Instant createdAt,
        Instant updatedAt,
        Instant lastIngestAt,
        Integer lastIngestFiles,
        Integer lastIngestChunks,
        List<String> lastIngestSkipped,
        boolean linkedWithoutReindex
) {}
