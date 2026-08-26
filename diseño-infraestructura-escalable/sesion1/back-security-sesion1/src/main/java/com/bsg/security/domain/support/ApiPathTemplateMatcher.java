package com.bsg.security.domain.support;

import java.util.ArrayList;
import java.util.List;
import java.util.regex.Pattern;

/**
 * Coincidencia de rutas API declaradas en BD con plantillas estilo OpenAPI ({@code {id}}, {@code {cellId}}).
 * Lógica pura de dominio, sin dependencias de infraestructura.
 */
public final class ApiPathTemplateMatcher {

    private static final Pattern TEMPLATE_SEGMENT = Pattern.compile("^\\{[a-zA-Z0-9_-]+}$");

    private ApiPathTemplateMatcher() {}

    /**
     * Indica si la ruta real coincide con la plantilla (mismo número de segmentos; cada {@code {param}} absorbe un segmento).
     */
    public static boolean matches(String templatePath, String actualPath) {
        List<String> t = segments(normalize(templatePath));
        List<String> a = segments(normalize(actualPath));
        if (t.size() != a.size()) {
            return false;
        }
        for (int i = 0; i < t.size(); i++) {
            if (isTemplateSegment(t.get(i))) {
                continue;
            }
            if (!t.get(i).equals(a.get(i))) {
                return false;
            }
        }
        return true;
    }

    /** Segmentos literales (no plantilla): a mayor valor, patrón más específico. */
    public static int literalSegmentCount(String templatePath) {
        int n = 0;
        for (String s : segments(normalize(templatePath))) {
            if (!isTemplateSegment(s)) {
                n++;
            }
        }
        return n;
    }

    public static int segmentCount(String path) {
        return segments(normalize(path)).size();
    }

    public static String normalize(String path) {
        if (path == null || path.isBlank()) {
            return "/";
        }
        String p = path.trim();
        if (!p.startsWith("/")) {
            p = "/" + p;
        }
        while (p.length() > 1 && p.endsWith("/")) {
            p = p.substring(0, p.length() - 1);
        }
        return p;
    }

    private static boolean isTemplateSegment(String segment) {
        return segment != null && TEMPLATE_SEGMENT.matcher(segment).matches();
    }

    private static List<String> segments(String normalizedPath) {
        String p = normalizedPath == null ? "/" : normalizedPath;
        if ("/".equals(p)) {
            return List.of();
        }
        String[] parts = p.split("/");
        List<String> out = new ArrayList<>(parts.length);
        for (String part : parts) {
            if (part != null && !part.isEmpty()) {
                out.add(part);
            }
        }
        return out;
    }
}
