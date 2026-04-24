package com.bsg.docviz.context;

/**
 * Hilo de conversación del chat RAG (Firestore: {@code users/{uid}/conversations/{id}/messages}).
 */
public final class DocvizChatContext {

    private static final ThreadLocal<String> CONVERSATION_ID = new ThreadLocal<>();

    private DocvizChatContext() {}

    public static void setConversationId(String id) {
        if (id == null || id.isBlank()) {
            CONVERSATION_ID.remove();
        } else {
            CONVERSATION_ID.set(id.trim());
        }
    }

    public static String conversationIdOrDefault() {
        String s = CONVERSATION_ID.get();
        return s != null && !s.isBlank() ? s : ChatConversationIds.DEFAULT;
    }

    public static void clear() {
        CONVERSATION_ID.remove();
    }
}
