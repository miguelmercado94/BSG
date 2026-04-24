package com.bsg.docviz.util;

import com.bsg.docviz.vector.VectorMatch;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * En búsqueda RAG, si el índice contiene el original y copias de área de trabajo ({@code *_vN.ext}),
 * conserva solo los fragmentos de la versión numérica más alta por archivo lógico.
 */
public final class WorkAreaVersionPreference {

    private static final Pattern VERSIONED_FILE =
            Pattern.compile("(?i)^(.+)_v(\\d+)(\\..+)$");

    private WorkAreaVersionPreference() {}

    public static List<VectorMatch> preferLatestWorkArea(List<VectorMatch> matches, String repoLabel) {
        if (matches == null || matches.isEmpty()) {
            return matches;
        }
        Map<String, Integer> maxVersionByKey = new HashMap<>();
        Map<String, List<VectorMatch>> byKey = new HashMap<>();
        for (VectorMatch m : matches) {
            String rel = repoRelativeFromDisplay(m.source(), repoLabel);
            String key = canonicalKey(rel);
            int v = versionOfBasename(basename(rel));
            byKey.computeIfAbsent(key, k -> new ArrayList<>()).add(m);
            maxVersionByKey.merge(key, v, Math::max);
        }
        List<VectorMatch> out = new ArrayList<>();
        for (Map.Entry<String, List<VectorMatch>> e : byKey.entrySet()) {
            int maxV = maxVersionByKey.getOrDefault(e.getKey(), 0);
            for (VectorMatch m : e.getValue()) {
                String rel = repoRelativeFromDisplay(m.source(), repoLabel);
                int v = versionOfBasename(basename(rel));
                if (v == maxV) {
                    out.add(m);
                }
            }
        }
        return out;
    }

    private static String basename(String rel) {
        int s = rel.lastIndexOf('/');
        return s >= 0 ? rel.substring(s + 1) : rel;
    }

    private static String canonicalKey(String relPath) {
        int slash = relPath.lastIndexOf('/');
        String dir = slash >= 0 ? relPath.substring(0, slash + 1) : "";
        String file = slash >= 0 ? relPath.substring(slash + 1) : relPath;
        Matcher m = VERSIONED_FILE.matcher(file);
        String canonFile = m.matches() ? m.group(1) + m.group(3) : file;
        return dir + canonFile;
    }

    private static int versionOfBasename(String fileName) {
        Matcher m = VERSIONED_FILE.matcher(fileName);
        if (m.matches()) {
            return Integer.parseInt(m.group(2));
        }
        return 0;
    }

    private static String repoRelativeFromDisplay(String sourceDisplay, String repoLabel) {
        if (repoLabel == null || repoLabel.isBlank()) {
            return sourceDisplay;
        }
        String prefix = repoLabel + "/";
        if (sourceDisplay.toLowerCase(Locale.ROOT).startsWith(prefix.toLowerCase(Locale.ROOT))) {
            return sourceDisplay.substring(prefix.length());
        }
        return sourceDisplay;
    }
}
