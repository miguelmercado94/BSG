package com.bsg.docviz.util;

import java.nio.file.Path;
import java.util.Locale;

/** Clave estable para comparar la misma URL/repo entre células. */
public final class RepositoryUrlNormalizer {

    private RepositoryUrlNormalizer() {}

    public static String normalizeRepositoryKey(String repositoryUrl, String localPath, String connectionMode) {
        if (connectionMode != null && "LOCAL".equalsIgnoreCase(connectionMode)) {
            if (localPath == null || localPath.isBlank()) {
                return "";
            }
            try {
                String abs = Path.of(localPath.trim()).toAbsolutePath().normalize().toString();
                return "local:" + abs.toLowerCase(Locale.ROOT);
            } catch (Exception e) {
                return "local:" + localPath.trim().toLowerCase(Locale.ROOT);
            }
        }
        return normalizeHttpsStyleUrl(repositoryUrl);
    }

    public static String normalizeHttpsStyleUrl(String repositoryUrl) {
        if (repositoryUrl == null || repositoryUrl.isBlank()) {
            return "";
        }
        String u = repositoryUrl.replace('\\', '/').trim().toLowerCase(Locale.ROOT);
        int q = u.indexOf('?');
        if (q >= 0) {
            u = u.substring(0, q);
        }
        while (u.endsWith("/")) {
            u = u.substring(0, u.length() - 1);
        }
        if (u.endsWith(".git")) {
            u = u.substring(0, u.length() - 4);
        }
        return u;
    }

    public static String clampNamespace(String ns, int maxLen) {
        if (ns == null) {
            return "";
        }
        String s = ns.replaceAll("[^a-zA-Z0-9._-]", "_");
        if (s.length() > maxLen) {
            return s.substring(0, maxLen);
        }
        return s;
    }
}
