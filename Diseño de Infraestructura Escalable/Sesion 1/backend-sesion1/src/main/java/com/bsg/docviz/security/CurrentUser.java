package com.bsg.docviz.security;

public final class CurrentUser {

    private static final ThreadLocal<String> HOLDER = new ThreadLocal<>();

    private CurrentUser() {
    }

    public static void set(String userId) {
        HOLDER.set(userId);
    }

    public static void clear() {
        HOLDER.remove();
    }

    public static String require() {
        String u = HOLDER.get();
        if (u == null || u.isBlank()) {
            throw new IllegalStateException("Missing X-DocViz-User");
        }
        return u;
    }
}
