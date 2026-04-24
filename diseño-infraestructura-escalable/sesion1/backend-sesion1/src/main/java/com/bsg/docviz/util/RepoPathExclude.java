package com.bsg.docviz.util;

import java.util.ArrayList;
import java.util.List;
import java.util.Locale;

/**
 * Filtra rutas de repositorio para el explorador y la ingesta: carpetas de build, dependencias y wrappers
 * que ensucian el árbol y no aportan al RAG (no indexables de todas formas).
 */
public final class RepoPathExclude {

    private RepoPathExclude() {
    }

    /**
     * Rutas relativas que no deben mostrarse en el árbol ni procesarse en ingesta vectorial.
     */
    public static List<String> filterWorkspacePaths(List<String> paths) {
        if (paths == null || paths.isEmpty()) {
            return paths;
        }
        List<String> out = new ArrayList<>(paths.size());
        for (String p : paths) {
            if (p != null && !p.isBlank() && !shouldExclude(p)) {
                out.add(p);
            }
        }
        return out;
    }

    static boolean shouldExclude(String relPath) {
        String n = normalize(relPath);
        if (n.isEmpty()) {
            return true;
        }
        // Maven
        if (segmentEquals(n, "target") || n.contains("/target/")) {
            return true;
        }
        // npm / frontend
        if (segmentEquals(n, "node_modules") || n.contains("/node_modules/")) {
            return true;
        }
        // Gradle cache
        if (n.startsWith(".gradle/") || n.contains("/.gradle/")) {
            return true;
        }
        // Python
        if (segmentEquals(n, "__pycache__") || n.contains("/__pycache__/")) {
            return true;
        }
        // Salidas de Gradle (no excluimos build.gradle / .kts: son fuente útil para el RAG)
        if (n.contains("/build/classes/")
                || n.contains("/build/libs/")
                || n.contains("/build/tmp/")
                || n.contains("/build/generated/")
                || n.contains("/build/resources/")) {
            return true;
        }
        // IntelliJ / Eclipse
        if (n.contains("/out/production/")
                || n.contains("/out/test/")
                || n.contains("/bin/main/")
                || n.contains("/bin/test/")) {
            return true;
        }
        // Wrappers y metadatos de build (no fuente)
        String lower = n.toLowerCase(Locale.ROOT);
        if (lower.endsWith("/mvnw")
                || lower.endsWith("/mvnw.cmd")
                || lower.endsWith("/gradlew")
                || lower.endsWith("/gradlew.bat")) {
            return true;
        }
        if (lower.endsWith("/meta-inf/manifest.mf")) {
            return true;
        }
        // IDE
        if (n.startsWith(".idea/") || n.contains("/.idea/")) {
            return true;
        }
        return false;
    }

    private static String normalize(String relPath) {
        String s = relPath.replace('\\', '/').trim();
        while (s.startsWith("/")) {
            s = s.substring(1);
        }
        return s;
    }

    private static boolean segmentEquals(String normalizedPath, String segment) {
        if (normalizedPath.equals(segment)) {
            return true;
        }
        return normalizedPath.startsWith(segment + "/") || normalizedPath.contains("/" + segment + "/");
    }
}
