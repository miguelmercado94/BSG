package com.bsg.docviz.repository;

import java.time.Instant;

public record TaskEntity(
        long id,
        String userId,
        String huCode,
        long cellRepoId,
        String enunciado,
        String status,
        Instant createdAt,
        Instant continuedAt,
        /** Firestore: {@code users/{uid}/conversations/{id}/messages}; id típico {@code usuario_[celula_]hu_taskId_N}. */
        String chatConversationId
) {}
