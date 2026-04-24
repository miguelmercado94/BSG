package com.bsg.docviz.util;

import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Extrae menciones {@code @[repo:ruta]}, {@code @[soporte:claveS3]}, rutas {@code @[a/b/c.java]} o
 * {@code @[Archivo.java]} (solo nombre).
 */
public final class RagMentionParser {

    private static final Pattern P_REPO = Pattern.compile("@\\[repo:([^\\]]+)\\]");
    private static final Pattern P_SOPORTE = Pattern.compile("@\\[soporte:([^\\]]+)\\]");
    /** Ruta con al menos una barra, sin prefijos repo:/soporte: */
    private static final Pattern P_PATH = Pattern.compile("@\\[((?:[^\\[\\]]+/)+[^\\[\\]]+)\\]");
    private static final Pattern P_ANY_BRACKET = Pattern.compile("@\\[([^\\]]+)\\]");

    public enum Kind {
        REPO_RELATIVE,
        SOPORTE_OBJECT_KEY,
        LEGACY_BASENAME
    }

    public record Mention(Kind kind, String value) {}

    private RagMentionParser() {}

    public static List<Mention> parse(String question) {
        if (question == null || question.isBlank()) {
            return List.of();
        }
        List<Mention> out = new ArrayList<>();
        Set<String> dedupe = new LinkedHashSet<>();

        addRepoPrefixed(question, out, dedupe);
        addSoporte(question, out, dedupe);
        addSlashPaths(question, out, dedupe);
        addBasenamesOnly(question, out, dedupe);
        return out;
    }

    /** Quita menciones ya interpretadas para detectar solo @{[nombre.ext]} sueltos. */
    private static String stripRepoSoporteAndSlash(String question) {
        String s = P_REPO.matcher(question).replaceAll(" ");
        s = P_SOPORTE.matcher(s).replaceAll(" ");
        return P_PATH.matcher(s).replaceAll(" ");
    }

    /** Texto extra para el embedding: refuerza la búsqueda vectorial con las rutas/claves citadas. */
    public static String embeddingAugmentation(String question) {
        List<Mention> m = parse(question);
        if (m.isEmpty()) {
            return question;
        }
        StringBuilder sb = new StringBuilder(question);
        for (Mention x : m) {
            sb.append(' ').append(x.value());
        }
        return sb.toString();
    }

    private static void addRepoPrefixed(String question, List<Mention> out, Set<String> dedupe) {
        Matcher m = P_REPO.matcher(question);
        while (m.find()) {
            String v = normalizePath(m.group(1));
            if (v.isEmpty()) {
                continue;
            }
            if (dedupe.add("repo:" + v)) {
                out.add(new Mention(Kind.REPO_RELATIVE, v));
            }
        }
    }

    private static void addSoporte(String question, List<Mention> out, Set<String> dedupe) {
        Matcher m = P_SOPORTE.matcher(question);
        while (m.find()) {
            String v = m.group(1).trim();
            if (v.isEmpty()) {
                continue;
            }
            if (dedupe.add("soporte:" + v)) {
                out.add(new Mention(Kind.SOPORTE_OBJECT_KEY, v));
            }
        }
    }

    private static void addSlashPaths(String question, List<Mention> out, Set<String> dedupe) {
        Matcher m = P_PATH.matcher(question);
        while (m.find()) {
            String inner = m.group(1).trim();
            if (inner.startsWith("repo:") || inner.startsWith("soporte:")) {
                continue;
            }
            String v = normalizePath(inner);
            if (v.isEmpty() || !v.contains("/")) {
                continue;
            }
            if (dedupe.add("path:" + v)) {
                out.add(new Mention(Kind.REPO_RELATIVE, v));
            }
        }
    }

    private static void addBasenamesOnly(String question, List<Mention> out, Set<String> dedupe) {
        String stripped = stripRepoSoporteAndSlash(question);
        Matcher m = P_ANY_BRACKET.matcher(stripped);
        while (m.find()) {
            String inner = m.group(1).trim();
            if (inner.isEmpty() || inner.contains("/") || inner.contains(":")) {
                continue;
            }
            if (dedupe.contains("repo:" + inner)
                    || dedupe.contains("soporte:" + inner)
                    || dedupe.contains("path:" + inner)) {
                continue;
            }
            if (dedupe.add("base:" + inner)) {
                out.add(new Mention(Kind.LEGACY_BASENAME, inner));
            }
        }
    }

    private static String normalizePath(String s) {
        if (s == null) {
            return "";
        }
        return s.replace('\\', '/').trim().replaceAll("^/+", "");
    }
}
