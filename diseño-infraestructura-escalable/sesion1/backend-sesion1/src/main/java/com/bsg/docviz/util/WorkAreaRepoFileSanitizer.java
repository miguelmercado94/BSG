package com.bsg.docviz.util;

import java.util.ArrayList;
import java.util.List;

/**
 * Limpia copias del repo que por error contienen líneas tipo merge ({@code <<<<<<<}, {@code =======}, {@code >>>>>>>})
 * pegadas dentro del YAML (p. ej. exportaciones previas del área de trabajo).
 */
public final class WorkAreaRepoFileSanitizer {

    private WorkAreaRepoFileSanitizer() {}

    /**
     * Elimina líneas que son únicamente marcadores de conflicto Git/DocViz; no altera el resto del texto.
     */
    public static String stripDocvizMergeMarkerLines(String text) {
        if (text == null || text.isEmpty()) {
            return text == null ? "" : text;
        }
        String[] lines = text.split("\r?\n", -1);
        List<String> out = new ArrayList<>(lines.length);
        for (String line : lines) {
            String t = line.trim();
            if (t.startsWith("<<<<<<<") || "=======".equals(t) || t.startsWith(">>>>>>>")) {
                continue;
            }
            out.add(line);
        }
        return String.join("\n", out);
    }
}
