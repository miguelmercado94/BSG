package com.bsg.docviz.repository;

import java.time.Instant;

public record CellRepoEntity(
        long id,
        /** Null = indexado y pendiente de asignar a una célula. */
        Long cellId,
        String displayName,
        String repositoryUrl,
        String connectionMode,
        String gitUsername,
        String credentialEncrypted,
        String localPath,
        String tagsCsv,
        String vectorNamespace,
        boolean active,
        Instant createdAt,
        Instant updatedAt,
        Instant lastIngestAt,
        Integer lastIngestFiles,
        Integer lastIngestChunks,
        String lastIngestSkippedJson,
        boolean linkedWithoutReindex
) {}
