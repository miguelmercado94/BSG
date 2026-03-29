package com.bsg.docviz.security;

public final class UserIdSanitizer {

    private static final int MAX_LEN = 64;

    private UserIdSanitizer() {
    }

    public static String forFilesystem(String raw) {
        if (raw == null) {
            throw new IllegalArgumentException("user id is required");
        }
        String t = raw.trim();
        if (t.isEmpty()) {
            throw new IllegalArgumentException("user id is required");
        }
        if (t.length() > MAX_LEN) {
            t = t.substring(0, MAX_LEN);
        }
        return t.replaceAll("[^a-zA-Z0-9._-]", "_");
    }
}
