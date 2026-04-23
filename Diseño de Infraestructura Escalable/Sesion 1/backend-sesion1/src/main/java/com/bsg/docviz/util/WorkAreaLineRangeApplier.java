package com.bsg.docviz.util;

import com.bsg.docviz.dto.WorkAreaLineEditDto;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;

/**
 * Aplica sustituciones por rangos de líneas (coordenadas del archivo original) sin que el modelo envíe el archivo entero.
 * Los rangos no deben solaparse; se aplican de la línea más alta a la más baja para no desplazar índices.
 */
public final class WorkAreaLineRangeApplier {

    private WorkAreaLineRangeApplier() {}

    public static String apply(String originalText, List<WorkAreaLineEditDto> edits) {
        if (edits == null || edits.isEmpty()) {
            return originalText;
        }
        boolean endsWithNewline = originalText != null && originalText.endsWith("\n");
        List<String> lines = splitLines(originalText);
        validateNoOverlap(edits);
        List<WorkAreaLineEditDto> desc = new ArrayList<>(edits);
        desc.sort(Comparator.comparingInt(WorkAreaLineEditDto::getStartLine).reversed());
        for (WorkAreaLineEditDto e : desc) {
            int n = lines.size();
            int startLine = e.getStartLine();
            int endLine = e.getEndLine();
            if (startLine < 1 || endLine < startLine) {
                throw new IllegalArgumentException(
                        "lineEdits inválido: startLine=" + startLine + ", endLine=" + endLine);
            }
            if (startLine > n) {
                throw new IllegalArgumentException(
                        "lineEdits fuera de rango: startLine=" + startLine + " (archivo tiene " + n + " líneas)");
            }
            int start0 = startLine - 1;
            int endExclusive = Math.min(endLine, n);
            if (start0 >= endExclusive) {
                continue;
            }
            List<String> replacementLines = splitReplacement(e.getReplacement());
            lines.subList(start0, endExclusive).clear();
            lines.addAll(start0, replacementLines);
        }
        return joinLines(lines, endsWithNewline);
    }

    static void validateNoOverlap(List<WorkAreaLineEditDto> edits) {
        List<WorkAreaLineEditDto> asc = new ArrayList<>(edits);
        asc.sort(Comparator.comparingInt(WorkAreaLineEditDto::getStartLine));
        for (int i = 1; i < asc.size(); i++) {
            WorkAreaLineEditDto prev = asc.get(i - 1);
            WorkAreaLineEditDto cur = asc.get(i);
            if (cur.getStartLine() <= prev.getEndLine()) {
                throw new IllegalArgumentException(
                        "lineEdits solapados: [" + prev.getStartLine() + "-" + prev.getEndLine() + "] y ["
                                + cur.getStartLine() + "-" + cur.getEndLine() + "]");
            }
        }
    }

    private static List<String> splitReplacement(String replacement) {
        if (replacement == null || replacement.isEmpty()) {
            return List.of();
        }
        return splitLines(replacement);
    }

    /** Misma semántica que {@link WorkAreaPartialDiffApplier} para líneas del archivo. */
    static List<String> splitLines(String s) {
        if (s == null || s.isEmpty()) {
            return new ArrayList<>();
        }
        String[] split = s.split("\\r?\\n", -1);
        List<String> out = new ArrayList<>(split.length);
        for (String line : split) {
            out.add(line);
        }
        if (out.size() > 1 && out.get(out.size() - 1).isEmpty()) {
            out.remove(out.size() - 1);
        }
        return out;
    }

    static String joinLines(List<String> lines, boolean endsWithNewline) {
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
