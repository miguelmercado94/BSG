package com.bsg.docviz.util;

/**
 * Marcadores de merge para borradores {@code *_vN.*.txt}: alineados con el contrato DocViz / YAML (ORIGINAL vs
 * SUGGESTION) y compatibilidad con borradores antiguos que usaban el texto "DocViz (original)".
 */
public final class WorkAreaMergeConflictFormatter {

    public static final String MARKER_OURS = "<<<<<<< ORIGINAL";
    public static final String MARKER_DIV = "=======";
    public static final String MARKER_THEIRS = ">>>>>>> SUGGESTION";

    /** Borradores persistidos antes del cambio de marcadores (solo parser / detección). */
    public static final String LEGACY_MARKER_OURS = "<<<<<<< DocViz (original)";

    public static final String LEGACY_MARKER_THEIRS = ">>>>>>> DocViz (propuesto)";

    private WorkAreaMergeConflictFormatter() {}

    /**
     * Un bloque de conflicto: original, separador, marcador de sugerencia, texto revisado y separador final (como en el
     * flujo YAML del modelo).
     */
    public static String format(String originalText, String revisedText) {
        String o = originalText == null ? "" : originalText;
        String r = revisedText == null ? "" : revisedText;
        return MARKER_OURS
                + "\n"
                + o
                + "\n"
                + MARKER_DIV
                + "\n"
                + MARKER_THEIRS
                + "\n"
                + r
                + "\n"
                + MARKER_DIV
                + "\n";
    }

    /** {@code true} si el borrador sigue con bloques de merge sin resolver (formato actual o legado). */
    public static boolean hasConflictMarkers(String text) {
        if (text == null) {
            return false;
        }
        boolean hasOurs = text.contains(MARKER_OURS) || text.contains(LEGACY_MARKER_OURS);
        boolean hasTheirs = text.contains(MARKER_THEIRS) || text.contains(LEGACY_MARKER_THEIRS);
        return hasOurs && text.contains(MARKER_DIV) && hasTheirs;
    }
}
