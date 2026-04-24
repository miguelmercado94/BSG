package com.bsg.docviz.support;

/**
 * Prefijo en {@code docviz_vector_chunk.source} para chunks que se resuelven leyendo el objeto en S3 (no desde Git).
 */
public final class SupportMarkdownConstants {

    public static final String SOURCE_PREFIX = "soporte:";

    private SupportMarkdownConstants() {
    }

    public static String sourceForObjectKey(String objectKey) {
        return SOURCE_PREFIX + objectKey;
    }

    public static String objectKeyFromSource(String source) {
        if (source == null || !source.startsWith(SOURCE_PREFIX)) {
            return null;
        }
        return source.substring(SOURCE_PREFIX.length());
    }
}
