package com.bsg.docviz.util;

import java.util.regex.Pattern;

/**
 * Borrador en el clon. Regla con ejemplo concreto:
 * <p>
 * {@code archivo.java} (original en el repo) → {@code archivo_v1.java.txt} — se repite la <strong>extensión real</strong>
 * ({@code java}, {@code yml}, …), no un sufijo literal «ext».
 * </p>
 * En general: {@code nombreBase + "_v" + N + "." + mismaExtensiónQueElOriginal + ".txt"}.
 * Si el original no tiene extensión: {@code nombreBase_vN.txt}.
 * <p>
 * Si el LLM envía el nombre mal (p. ej. {@code archivo.java_v1}), se corrige a {@code archivo.java} antes.
 */
public final class WorkAreaDraftPathBuilder {

    /** {@code docker-compose.yml_v1} o {@code .yml_V1} pegado al stem — se vuelve a {@code docker-compose.yml}. */
    private static final Pattern WRONG_VERSION_AFTER_EXT =
            Pattern.compile("^(.+)\\.([^.]+)_[vV](\\d+)$");

    private WorkAreaDraftPathBuilder() {}

    public static String normalizeRelPath(String src) {
        if (src == null) {
            return "";
        }
        String s = src.trim().replace('\\', '/');
        while (s.startsWith("/")) {
            s = s.substring(1);
        }
        return s;
    }

    /**
     * Último segmento con nombre lógico de repo (por si el JSON trae {@code foo.yml_v1}).
     */
    public static String normalizeSourceRelativePath(String relPath) {
        String r = normalizeRelPath(relPath);
        if (r.isEmpty()) {
            return r;
        }
        int ls = r.lastIndexOf('/');
        String last = ls >= 0 ? r.substring(ls + 1) : r;
        String fixed = sanitizeFileNameLikeOriginalInRepo(last);
        if (fixed.equals(last)) {
            return r;
        }
        return ls >= 0 ? r.substring(0, ls + 1) + fixed : fixed;
    }

    /**
     * Nombre como en el repo: quita un {@code _vN} mal colocado tras la extensión real (p. ej. {@code .java_v1}).
     */
    public static String sanitizeFileNameLikeOriginalInRepo(String fileName) {
        if (fileName == null || fileName.isBlank()) {
            return fileName;
        }
        String f = fileName.trim();
        var m = WRONG_VERSION_AFTER_EXT.matcher(f);
        if (m.matches()) {
            return m.group(1) + "." + m.group(2);
        }
        return f;
    }

    /**
     * P. ej. fuente {@code src/Foo.java} → borrador {@code src/Foo_v1.java.txt} (misma extensión {@code .java} que el original).
     */
    public static String buildDraftTxtPath(String sourceRelativePath, int version) {
        if (version < 1) {
            throw new IllegalArgumentException("version must be >= 1");
        }
        String rel = normalizeSourceRelativePath(sourceRelativePath);
        int slash = rel.lastIndexOf('/');
        String dir = slash >= 0 ? rel.substring(0, slash) : "";
        String file = slash >= 0 ? rel.substring(slash + 1) : rel;
        file = sanitizeFileNameLikeOriginalInRepo(file);

        int dot = file.lastIndexOf('.');
        String stem;
        String extNoDot;
        if (dot > 0) {
            stem = file.substring(0, dot);
            extNoDot = fixExtSegment(file.substring(dot + 1));
        } else {
            stem = file;
            extNoDot = "";
        }

        String draftName =
                stem + "_v" + version + (extNoDot.isEmpty() ? "" : "." + extNoDot) + ".txt";
        if (dir.isEmpty()) {
            return draftName;
        }
        return dir + "/" + draftName;
    }

    /**
     * Si la parte tras el último punto vino como {@code java_v1} en vez de {@code java}, la deja en {@code java}.
     */
    private static String fixExtSegment(String extWithoutDot) {
        if (extWithoutDot == null || extWithoutDot.isEmpty()) {
            return "";
        }
        var m = Pattern.compile("^([^.]+)_[vV](\\d+)$").matcher(extWithoutDot);
        if (m.matches()) {
            return m.group(1);
        }
        return extWithoutDot;
    }

    public static String buildDraftTxtPath(String sourceRelativePath) {
        return buildDraftTxtPath(sourceRelativePath, 1);
    }

    /** Quita el {@code .txt} del borrador → ruta del aceptado {@code *_vN.ext}. */
    public static String acceptedPathFromDraftTxt(String draftTxtRelativePath) {
        String rel = normalizeRelPath(draftTxtRelativePath);
        if (!rel.endsWith(".txt")) {
            return rel;
        }
        return rel.substring(0, rel.length() - 4);
    }

}
