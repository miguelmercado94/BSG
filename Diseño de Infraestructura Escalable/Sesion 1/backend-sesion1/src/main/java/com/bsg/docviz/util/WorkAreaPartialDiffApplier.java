package com.bsg.docviz.util;

import com.bsg.docviz.dto.WorkAreaDiffLineDto;

import java.util.ArrayList;
import java.util.List;

/**
 * Aplica la secuencia reducida del LLM (context / removed / added) sobre el texto original
 * para obtener el texto revisado sin que el modelo envíe el archivo entero.
 */
public final class WorkAreaPartialDiffApplier {

    private WorkAreaPartialDiffApplier() {}

    public static String apply(String originalText, List<WorkAreaDiffLineDto> diffLines) {
        if (diffLines == null || diffLines.isEmpty()) {
            return originalText;
        }
        List<String> orig = splitLines(originalText);
        StringBuilder out = new StringBuilder();
        int i = 0;
        for (WorkAreaDiffLineDto d : diffLines) {
            String kind = normalizeKind(d.getKind());
            String text = d.getText() != null ? d.getText() : "";
            switch (kind) {
                case "removed" -> {
                    if (i >= orig.size()) {
                        break;
                    }
                    if (linesMatch(orig.get(i), text)) {
                        i++;
                    } else {
                        i++;
                    }
                }
                case "added" -> out.append(text).append('\n');
                case "context" -> {
                    if (i < orig.size()) {
                        out.append(orig.get(i)).append('\n');
                        i++;
                    }
                }
                default -> {
                }
            }
        }
        while (i < orig.size()) {
            out.append(orig.get(i)).append('\n');
            i++;
        }
        if (out.length() == 0) {
            return originalText;
        }
        String s = out.toString();
        if (originalText.endsWith("\n") && !s.endsWith("\n")) {
            return s + "\n";
        }
        if (!originalText.endsWith("\n") && s.endsWith("\n")) {
            return s.substring(0, s.length() - 1);
        }
        return s;
    }

    static String normalizeKind(String raw) {
        if (raw == null || raw.isBlank()) {
            return "context";
        }
        String k = raw.trim().toLowerCase();
        return switch (k) {
            case "unchanged", "equal" -> "context";
            default -> k;
        };
    }

    static boolean linesMatch(String a, String b) {
        if (a == null) {
            return b == null || b.isEmpty();
        }
        if (b == null) {
            return a.isEmpty();
        }
        return a.equals(b) || a.trim().equals(b.trim());
    }

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
}
