package com.bsg.docviz.context;

import com.bsg.docviz.security.UserIdSanitizer;

/** Identificador de hilo por defecto (workspace sin tarea o clientes antiguos). */
public final class ChatConversationIds {

    public static final String DEFAULT = "default";

    private ChatConversationIds() {}

    /**
     * Hilo por tarea e índice {@code N}: {@code usuario_hu_taskId_N} (sin célula; compatibilidad).
     * El chat “principal” a mostrar es siempre el **menor N** entre conversaciones existentes en Firestore.
     */
    public static String forUserHuTaskIdAndThread(String rawUserId, String huCode, long taskId, int threadIndex) {
        return forUserCellHuTaskIdAndThread(rawUserId, null, huCode, taskId, threadIndex);
    }

    /**
     * Hilo con célula: {@code usuario_celula_hu_taskId_N}. Si {@code cellName} es nulo o vacío, equivale al formato
     * sin célula ({@code usuario_hu_taskId_N}).
     */
    public static String forUserCellHuTaskIdAndThread(
            String rawUserId, String cellName, String huCode, long taskId, int threadIndex) {
        String u = UserIdSanitizer.forFilesystem(rawUserId);
        String t =
                (huCode == null || huCode.isBlank())
                        ? "default"
                        : UserIdSanitizer.forFilesystem(huCode.trim());
        String c =
                (cellName == null || cellName.isBlank())
                        ? null
                        : UserIdSanitizer.forFilesystem(cellName.trim());
        int n = Math.max(0, threadIndex);
        if (c == null || c.isBlank()) {
            return u + "_" + t + "_" + taskId + "_" + n;
        }
        return u + "_" + c + "_" + t + "_" + taskId + "_" + n;
    }
}
