package com.bsg.docviz.util;

import java.util.Locale;

/**
 * Decodifica {@code path} del YAML de propuestas: {@code REPO/…} o {@code LOCAL/…}.
 */
public final class WorkAreaProposalPathCodec {

    public enum Kind {
        REPO,
        LOCAL
    }

    public record Parsed(String raw, Kind kind, String repoRelativePath, String s3Bucket, String s3Key) {}

    private WorkAreaProposalPathCodec() {}

    /**
     * @param path p. ej. {@code REPO/findu/docker-compose.yml} o {@code LOCAL/mi-bucket/carpeta/objeto.yml}
     */
    public static Parsed parse(String path) {
        if (path == null || path.isBlank()) {
            throw new IllegalArgumentException("path vacío");
        }
        String p = path.trim().replace('\\', '/');
        int slash = p.indexOf('/');
        if (slash < 0) {
            throw new IllegalArgumentException("path debe empezar por REPO/ o LOCAL/: " + path);
        }
        String head = p.substring(0, slash).toUpperCase(Locale.ROOT);
        String rest = p.substring(slash + 1);
        if (rest.isBlank()) {
            throw new IllegalArgumentException("path sin ruta tras el prefijo: " + path);
        }
        if ("REPO".equals(head)) {
            return new Parsed(p, Kind.REPO, rest, null, null);
        }
        if ("LOCAL".equals(head)) {
            int s = rest.indexOf('/');
            if (s < 0 || s == rest.length() - 1) {
                throw new IllegalArgumentException("LOCAL requiere bucket y key: LOCAL/{bucket}/{key}");
            }
            String bucket = rest.substring(0, s);
            String key = rest.substring(s + 1);
            if (bucket.isBlank() || key.isBlank()) {
                throw new IllegalArgumentException("LOCAL: bucket o key vacíos");
            }
            return new Parsed(p, Kind.LOCAL, null, bucket.trim(), key);
        }
        throw new IllegalArgumentException("La primera palabra del path debe ser REPO o LOCAL: " + path);
    }

    /** Ruta relativa en el clon para borradores de objetos importados desde S3 LOCAL. */
    public static String syntheticRepoRelativePath(Parsed parsed) {
        if (parsed.kind() != Kind.LOCAL) {
            return parsed.repoRelativePath();
        }
        return "local-import/" + sanitizeSegment(parsed.s3Bucket()) + "/" + parsed.s3Key().replace('\\', '/');
    }

    private static String sanitizeSegment(String s) {
        String t = s.replace("..", "").replace('/', '_').trim();
        return t.isEmpty() ? "bucket" : t;
    }
}
