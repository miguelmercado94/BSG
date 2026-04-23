package com.bsg.docviz.security;

import java.util.Optional;

public final class CurrentUser {

    public static final String ROLE_HEADER = "X-DocViz-Role";

    private static final ThreadLocal<String> HOLDER = new ThreadLocal<>();
    private static final ThreadLocal<String> ROLE_HOLDER = new ThreadLocal<>();

    private CurrentUser() {
    }

    public static void set(String userId) {
        HOLDER.set(userId);
    }

    public static void setRole(String role) {
        ROLE_HOLDER.set(role);
    }

    public static void clear() {
        HOLDER.remove();
        ROLE_HOLDER.remove();
    }

    public static String require() {
        String u = HOLDER.get();
        if (u == null || u.isBlank()) {
            throw new IllegalStateException("Missing X-DocViz-User");
        }
        return u;
    }

    public static Optional<String> role() {
        return Optional.ofNullable(ROLE_HOLDER.get());
    }

    /** Si no hay cabecera de rol, se asume administrador (compatibilidad). */
    public static boolean isAdministrator() {
        return DocvizRoles.ADMINISTRATOR.equals(role().orElse(DocvizRoles.ADMINISTRATOR));
    }

    public static boolean isSupport() {
        return DocvizRoles.SUPPORT.equals(role().orElse(null));
    }
}
