package com.bsg.docviz.util;

import com.bsg.docviz.dto.WorkAreaLineEditDto;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;

/**
 * Cola de ediciones por línea (orden ascendente por {@code startLine} en el archivo original). En cada paso se insertan
 * marcadores alrededor del bloque sustituido; el desplazamiento neto de líneas se acumula para los siguientes rangos.
 */
public final class WorkAreaLineMarkerQueueProcessor {

    public static final String MARK_PAST = ">>> past >>>";
    public static final String MARK_CURRENT = ">>> current >>>";

    private WorkAreaLineMarkerQueueProcessor() {}

    /**
     * Produce un único texto con todos los bloques marcados, procesando de arriba abajo (línea original menor primero).
     * Las coordenadas {@code startLine}/{@code endLine} son las del archivo original (como {@link WorkAreaLineRangeApplier}).
     */
    public static String buildMarkedDocument(String originalText, List<WorkAreaLineEditDto> edits) {
        if (edits == null || edits.isEmpty()) {
            return originalText == null ? "" : originalText;
        }
        List<WorkAreaLineEditDto> sorted = new ArrayList<>(edits);
        sorted.sort(Comparator.comparingInt(WorkAreaLineEditDto::getStartLine));
        WorkAreaLineRangeApplier.validateNoOverlap(sorted);

        boolean endsWithNewline = originalText != null && originalText.endsWith("\n");
        List<String> lines = WorkAreaLineRangeApplier.splitLines(originalText == null ? "" : originalText);
        int originalLineCount = lines.size();
        int shift = 0;

        for (WorkAreaLineEditDto ed : sorted) {
            int s = ed.getStartLine();
            int e = ed.getEndLine();
            if (s < 1 || e < s) {
                throw new IllegalArgumentException("lineEdit inválido: startLine=" + s + ", endLine=" + e);
            }
            if (s > originalLineCount) {
                throw new IllegalArgumentException(
                        "lineEdit fuera de rango: startLine=" + s + " (original tiene " + originalLineCount + " líneas)");
            }
            int effEnd = Math.min(e, originalLineCount);
            int span = effEnd - s + 1;
            int s0 = s - 1 + shift;
            int e0 = s0 + span - 1;
            if (s0 < 0 || s0 >= lines.size() || e0 >= lines.size() || e0 < s0) {
                throw new IllegalArgumentException(
                        "lineEdit fuera de rango tras desplazamiento: startLine="
                                + s
                                + " shift="
                                + shift
                                + " (buffer tiene "
                                + lines.size()
                                + " líneas)");
            }
            List<String> past = new ArrayList<>(lines.subList(s0, e0 + 1));
            List<String> repl = splitReplacementLines(ed.getReplacement());
            List<String> block = new ArrayList<>();
            block.add(MARK_PAST);
            block.addAll(past);
            block.add(MARK_CURRENT);
            block.addAll(repl);

            int oldLen = e0 - s0 + 1;
            int newLen = block.size();
            for (int i = 0; i < oldLen; i++) {
                lines.remove(s0);
            }
            lines.addAll(s0, block);
            shift += (newLen - oldLen);
        }
        return joinLines(lines, endsWithNewline);
    }

    private static List<String> splitReplacementLines(String replacement) {
        return WorkAreaLineRangeApplier.splitLines(replacement == null ? "" : replacement);
    }

    private static String joinLines(List<String> lines, boolean endsWithNewline) {
        if (lines.isEmpty()) {
            return endsWithNewline ? "\n" : "";
        }
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < lines.size(); i++) {
            if (i > 0) {
                sb.append('\n');
            }
            sb.append(lines.get(i));
        }
        if (endsWithNewline) {
            sb.append('\n');
        }
        return sb.toString();
    }
}
