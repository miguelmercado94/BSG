package com.bsg.docviz.context;

/**
 * Etiqueta de tarea (p. ej. código HU) para rutas S3 y logs; se fija en WebSocket / cabeceras HTTP opcionales.
 */
public final class DocvizTaskContext {

    private static final ThreadLocal<String> TASK_LABEL = new ThreadLocal<>();

    private DocvizTaskContext() {}

    public static void setTaskLabel(String label) {
        if (label == null || label.isBlank()) {
            TASK_LABEL.remove();
        } else {
            TASK_LABEL.set(label.trim());
        }
    }

    /** Carpeta estable para S3: nunca vacío. */
    public static String taskLabelOrDefault() {
        String s = TASK_LABEL.get();
        return s != null && !s.isBlank() ? s : "default";
    }

    /** Cabecera {@code X-DocViz-Task-Hu} en esta petición, o null. */
    public static String taskLabelOrNull() {
        String s = TASK_LABEL.get();
        return s != null && !s.isBlank() ? s.trim() : null;
    }

    public static void clear() {
        TASK_LABEL.remove();
    }
}
