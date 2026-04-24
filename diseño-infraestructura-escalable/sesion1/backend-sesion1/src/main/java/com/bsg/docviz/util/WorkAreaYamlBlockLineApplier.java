package com.bsg.docviz.util;

import com.bsg.docviz.dto.WorkAreaYamlProposalBlockDto;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Locale;

/**
 * Aplica bloques YAML ({@code REPLACE}, {@code NEW}, {@code DELETE}) sobre líneas del archivo original (coordenadas
 * 1-based del modelo). Varios bloques se aplican en orden de {@code end} descendente para conservar índices válidos.
 */
public final class WorkAreaYamlBlockLineApplier {

    private WorkAreaYamlBlockLineApplier() {}

    public static String apply(String originalText, List<WorkAreaYamlProposalBlockDto> blocks) {
        if (blocks == null || blocks.isEmpty()) {
            return originalText == null ? "" : originalText;
        }
        boolean endsWithNewline = originalText != null && originalText.endsWith("\n");
        List<String> lines = WorkAreaLineRangeApplier.splitLines(originalText);
        List<WorkAreaYamlProposalBlockDto> ordered = new ArrayList<>(blocks);
        ordered.sort(Comparator.comparingInt(WorkAreaYamlProposalBlockDto::getEnd).reversed());
        for (WorkAreaYamlProposalBlockDto b : ordered) {
            applyOne(lines, b);
        }
        return WorkAreaLineRangeApplier.joinLines(lines, endsWithNewline);
    }

    private static void applyOne(List<String> lines, WorkAreaYamlProposalBlockDto b) {
        String t = b.getType() != null ? b.getType().trim().toUpperCase(Locale.ROOT) : "";
        int start = b.getStart();
        int end = b.getEnd();
        if (start < 1 || end < 1) {
            throw new IllegalArgumentException("yaml block: start/end deben ser >= 1");
        }
        switch (t) {
            case "REPLACE" -> applyReplace(lines, start, end, blockLines(b));
            case "DELETE" -> applyReplace(lines, start, end, List.of());
            case "NEW" -> applyNew(lines, start, end, blockLines(b));
            default -> throw new IllegalArgumentException("yaml block: type desconocido: " + b.getType());
        }
    }

    private static List<String> blockLines(WorkAreaYamlProposalBlockDto b) {
        List<String> L = b.getLines();
        return L != null ? new ArrayList<>(L) : new ArrayList<>();
    }

    private static void applyReplace(List<String> lines, int startLine, int endLine, List<String> replacement) {
        if (endLine < startLine) {
            throw new IllegalArgumentException("REPLACE: end < start");
        }
        int n = lines.size();
        int start0 = startLine - 1;
        int endExclusive = Math.min(endLine, n);
        if (start0 > n) {
            throw new IllegalArgumentException(
                    "REPLACE: startLine=" + startLine + " fuera de rango (archivo tiene " + n + " líneas)");
        }
        if (start0 >= endExclusive && n == start0 && endLine == startLine) {
            // insertar al final (archivo sin newline final y rango al “hueco” final)
            lines.addAll(replacement);
            return;
        }
        if (start0 >= endExclusive) {
            throw new IllegalArgumentException("REPLACE: rango vacío inválido start=" + startLine + " end=" + endLine);
        }
        lines.subList(start0, endExclusive).clear();
        lines.addAll(start0, replacement);
    }

    /**
     * NEW: {@code start == end}. Si esa línea existe y está en blanco, se sustituye por {@code lines}; si no está en
     * blanco, se insertan las líneas nuevas antes de esa línea (equivalente a “enter” antes del bloque sugerido).
     */
    private static void applyNew(List<String> lines, int startLine, int endLine, List<String> insertLines) {
        if (startLine != endLine) {
            throw new IllegalArgumentException("NEW: start y end deben coincidir");
        }
        int idx = startLine - 1;
        while (lines.size() < idx) {
            lines.add("");
        }
        if (idx < lines.size()) {
            String cur = lines.get(idx);
            if (cur != null && cur.trim().isEmpty()) {
                lines.remove(idx);
                lines.addAll(idx, insertLines);
            } else {
                lines.addAll(idx, insertLines);
            }
        } else {
            lines.addAll(insertLines);
        }
    }
}
