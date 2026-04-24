package com.bsg.docviz.context;

/**
 * Nombre de célula (área de trabajo) para rutas S3 y hilo de chat; opcional vía WebSocket o cabecera HTTP.
 */
public final class DocvizCellContext {

    private static final ThreadLocal<String> CELL_NAME = new ThreadLocal<>();

    private DocvizCellContext() {}

    public static void setCellName(String name) {
        if (name == null || name.isBlank()) {
            CELL_NAME.remove();
        } else {
            CELL_NAME.set(name.trim());
        }
    }

    /** Segmento estable para prefijos S3; nunca vacío. */
    public static String cellNameOrDefault() {
        String s = CELL_NAME.get();
        return s != null && !s.isBlank() ? s : "default";
    }

    public static void clear() {
        CELL_NAME.remove();
    }
}
