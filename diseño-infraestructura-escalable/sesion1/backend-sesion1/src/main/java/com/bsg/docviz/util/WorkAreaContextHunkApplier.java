package com.bsg.docviz.util;

import com.bsg.docviz.dto.WorkAreaChangeBlockDto;

import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

/**
 * Aplica bloques de cambio anclados por contexto (como un parche Git), sin depender de números de línea fijos.
 */
public final class WorkAreaContextHunkApplier {

    private WorkAreaContextHunkApplier() {}

    public static String apply(String originalFileText, List<WorkAreaChangeBlockDto> blocks) {
        if (blocks == null || blocks.isEmpty()) {
            return originalFileText;
        }
        List<WorkAreaChangeBlockDto> nonCreate = new ArrayList<>();
        for (WorkAreaChangeBlockDto b : blocks) {
            if (b == null) {
                continue;
            }
            if ("create_file".equals(typeNorm(b.getType()))) {
                if (blocks.size() != 1) {
                    throw new IllegalArgumentException("create_file debe ser el único bloque en la lista");
                }
                return joinContentLines(b.getContent(), originalFileText);
            }
            nonCreate.add(b);
        }
        boolean endsWithNewline = originalFileText != null && originalFileText.endsWith("\n");
        String current = originalFileText == null ? "" : originalFileText;
        for (WorkAreaChangeBlockDto b : nonCreate) {
            current = applyOne(current, b, endsWithNewline);
        }
        return current;
    }

    private static String applyOne(String text, WorkAreaChangeBlockDto b, boolean endsWithNewline) {
        String t = typeNorm(b.getType());
        List<String> lines = WorkAreaLineRangeApplier.splitLines(text);
        List<String> cb = nz(b.getContextBefore());
        List<String> orig = nz(b.getOriginal());
        List<String> repl = nz(b.getReplacement());
        List<String> ca = nz(b.getContextAfter());

        return switch (t) {
            case "replace" -> {
                if (orig.isEmpty()) {
                    throw new IllegalArgumentException("replace: original no puede estar vacío");
                }
                yield applyReplace(lines, cb, orig, repl, ca, endsWithNewline);
            }
            case "insert" -> applyInsert(lines, cb, repl, ca, endsWithNewline);
            case "delete" -> {
                if (orig.isEmpty()) {
                    throw new IllegalArgumentException("delete: original no puede estar vacío");
                }
                yield applyDelete(lines, cb, orig, ca, endsWithNewline);
            }
            default -> throw new IllegalArgumentException("tipo de bloque no soportado: " + b.getType());
        };
    }

    private static String applyReplace(
            List<String> lines,
            List<String> cb,
            List<String> orig,
            List<String> repl,
            List<String> ca,
            boolean endsWithNewline) {
        int start = findUniqueMatch(lines, cb, orig, ca);
        int cbN = cb.size();
        int oN = orig.size();
        int caN = ca.size();
        List<String> out = new ArrayList<>();
        out.addAll(lines.subList(0, start));
        out.addAll(cb);
        out.addAll(repl);
        out.addAll(ca);
        out.addAll(lines.subList(start + cbN + oN + caN, lines.size()));
        return joinAsFile(out, endsWithNewline);
    }

    private static String applyDelete(
            List<String> lines, List<String> cb, List<String> orig, List<String> ca, boolean endsWithNewline) {
        int start = findUniqueMatch(lines, cb, orig, ca);
        int cbN = cb.size();
        int oN = orig.size();
        int caN = ca.size();
        List<String> out = new ArrayList<>();
        out.addAll(lines.subList(0, start));
        out.addAll(cb);
        out.addAll(ca);
        out.addAll(lines.subList(start + cbN + oN + caN, lines.size()));
        return joinAsFile(out, endsWithNewline);
    }

    private static String applyInsert(
            List<String> lines, List<String> cb, List<String> repl, List<String> ca, boolean endsWithNewline) {
        int start = findUniqueInsert(lines, cb, ca);
        int cbN = cb.size();
        List<String> out = new ArrayList<>();
        out.addAll(lines.subList(0, start + cbN));
        out.addAll(repl);
        out.addAll(lines.subList(start + cbN, lines.size()));
        return joinAsFile(out, endsWithNewline);
    }

    /** Ubicación única donde aparece cb + orig + ca como sublistas contiguas (cualquiera puede ser vacía salvo orig en replace/delete). */
    static int findUniqueMatch(List<String> lines, List<String> cb, List<String> orig, List<String> ca) {
        List<Integer> exact = findAllTripleMatches(lines, cb, orig, ca, false);
        if (exact.size() == 1) {
            return exact.get(0);
        }
        if (exact.size() > 1) {
            throw new IllegalArgumentException(
                    "el ancla no es única; añade más líneas en context_before o context_after. Fragmento: "
                            + anchorPreview(cb, orig, ca));
        }
        List<Integer> lenient = findAllTripleMatches(lines, cb, orig, ca, true);
        if (lenient.size() == 1) {
            return lenient.get(0);
        }
        if (lenient.size() > 1) {
            throw new IllegalArgumentException(
                    "el ancla no es única (comparación tolerante a espacios/saltos); acota más el contexto. Fragmento: "
                            + anchorPreview(cb, orig, ca));
        }
        throw new IllegalArgumentException(
                "no se encontró el ancla (context_before + original + context_after) en el archivo. "
                        + "Comprueba espacios/saltos de línea frente al archivo real. Fragmento buscado: "
                        + anchorPreview(cb, orig, ca));
    }

    private static List<Integer> findAllTripleMatches(
            List<String> lines, List<String> cb, List<String> orig, List<String> ca, boolean lenient) {
        List<Integer> out = new ArrayList<>();
        for (int start = 0; start <= lines.size(); start++) {
            if (matchTriple(lines, start, cb, orig, ca, lenient)) {
                out.add(start);
            }
        }
        return out;
    }

    static boolean matchTriple(List<String> lines, int i, List<String> cb, List<String> orig, List<String> ca) {
        return matchTriple(lines, i, cb, orig, ca, false);
    }

    static boolean matchTriple(
            List<String> lines, int i, List<String> cb, List<String> orig, List<String> ca, boolean lenient) {
        int p = i;
        if (!matchesAt(lines, p, cb, lenient)) {
            return false;
        }
        p += cb.size();
        if (!matchesAt(lines, p, orig, lenient)) {
            return false;
        }
        p += orig.size();
        return matchesAt(lines, p, ca, lenient);
    }

    /** Inserción: cb seguido inmediatamente por ca; se inserta repl entre ambos. */
    static int findUniqueInsert(List<String> lines, List<String> cb, List<String> ca) {
        int cbN = cb.size();
        int caN = ca.size();
        if (cbN == 0 && caN == 0) {
            throw new IllegalArgumentException("insert: context_before y context_after no pueden estar vacíos ambos");
        }
        List<Integer> exact = findAllInsertMatches(lines, cb, ca, false);
        if (exact.size() == 1) {
            return exact.get(0);
        }
        if (exact.size() > 1) {
            throw new IllegalArgumentException("insert: el ancla no es única. Fragmento: " + anchorPreview(cb, List.of(), ca));
        }
        List<Integer> lenient = findAllInsertMatches(lines, cb, ca, true);
        if (lenient.size() == 1) {
            return lenient.get(0);
        }
        if (lenient.size() > 1) {
            throw new IllegalArgumentException(
                    "insert: el ancla no es única (comparación tolerante). Fragmento: " + anchorPreview(cb, List.of(), ca));
        }
        throw new IllegalArgumentException(
                "insert: no se encontró context_before seguido de context_after. Fragmento: "
                        + anchorPreview(cb, List.of(), ca));
    }

    private static List<Integer> findAllInsertMatches(
            List<String> lines, List<String> cb, List<String> ca, boolean lenient) {
        int cbN = cb.size();
        List<Integer> out = new ArrayList<>();
        for (int start = 0; start <= lines.size(); start++) {
            if (matchesAt(lines, start, cb, lenient) && matchesAt(lines, start + cbN, ca, lenient)) {
                out.add(start);
            }
        }
        return out;
    }

    private static String joinAsFile(List<String> lines, boolean endsWithNewline) {
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

    private static String joinContentLines(List<String> content, String originalFileText) {
        List<String> c = nz(content);
        boolean ends = originalFileText == null || originalFileText.isEmpty()
                ? true
                : originalFileText.endsWith("\n");
        return joinAsFile(c, ends);
    }

    private static boolean matchesAt(List<String> lines, int start, List<String> part, boolean lenient) {
        if (part.isEmpty()) {
            return true;
        }
        if (start < 0 || start + part.size() > lines.size()) {
            return false;
        }
        for (int j = 0; j < part.size(); j++) {
            if (!lineEquals(lines.get(start + j), part.get(j), lenient)) {
                return false;
            }
        }
        return true;
    }

    /**
     * Comparación de línea: exacta, o tolerante (sin CR, trim) si el modelo y el archivo difieren solo en
     * indentación/espacios finales — habitual en YAML/docker-compose.
     */
    private static boolean lineEquals(String fileLine, String patternLine, boolean lenient) {
        if (!lenient) {
            return fileLine.equals(patternLine);
        }
        return normalizeLenientLine(fileLine).equals(normalizeLenientLine(patternLine));
    }

    private static String normalizeLenientLine(String s) {
        if (s == null) {
            return "";
        }
        return s.replace("\r", "").trim();
    }

    /** Primeras líneas del ancla para mensajes de error (evita volcar el archivo entero). */
    private static String anchorPreview(List<String> cb, List<String> orig, List<String> ca) {
        List<String> lines = new ArrayList<>();
        lines.addAll(nz(cb));
        lines.addAll(nz(orig));
        lines.addAll(nz(ca));
        int maxLines = 8;
        List<String> head = lines.stream().limit(maxLines).collect(Collectors.toList());
        String joined = String.join(" | ", head);
        if (joined.length() > 400) {
            return joined.substring(0, 397) + "…";
        }
        return joined.isEmpty() ? "(vacío)" : joined;
    }

    private static List<String> nz(List<String> list) {
        return list != null ? list : List.of();
    }

    private static String typeNorm(String t) {
        if (t == null || t.isBlank()) {
            return "";
        }
        return t.trim().toLowerCase();
    }
}
