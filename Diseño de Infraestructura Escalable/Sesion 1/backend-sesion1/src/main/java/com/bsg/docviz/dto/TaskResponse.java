package com.bsg.docviz.dto;

import java.time.Instant;

public record TaskResponse(
        long id,
        String userId,
        String huCode,
        long cellRepoId,
        String enunciado,
        String status,
        Instant createdAt,
        Instant continuedAt,
        /** Id de hilo RAG/Firestore asociado a esta tarea (usuario + HU + índice). */
        String chatConversationId
) {}
