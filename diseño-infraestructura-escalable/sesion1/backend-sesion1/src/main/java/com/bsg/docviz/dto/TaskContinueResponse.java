package com.bsg.docviz.dto;

public record TaskContinueResponse(
        long taskId,
        String huCode,
        long cellRepoId,
        GitConnectRequest gitConnect,
        String initialChatPrompt,
        String vectorNamespaceHint,
        /** Nombre de célula del repo (PostgreSQL); para cabeceras S3 y {@code cellName} en historial Firestore. */
        String cellName,
        /** Mismo valor persistido en {@code docviz_task.chat_conversation_id}. */
        String chatConversationId
) {}
