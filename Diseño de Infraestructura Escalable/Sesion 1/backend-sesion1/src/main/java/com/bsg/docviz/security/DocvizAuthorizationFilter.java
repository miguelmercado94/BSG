package com.bsg.docviz.security;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.http.MediaType;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.nio.charset.StandardCharsets;

/**
 * Rutas /admin/* solo ROLE_ADMINISTRATOR. Soporte no puede POST/DELETE en /support/markdown.
 */
public class DocvizAuthorizationFilter extends OncePerRequestFilter {

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
            throws ServletException, IOException {
        if ("OPTIONS".equalsIgnoreCase(request.getMethod())) {
            filterChain.doFilter(request, response);
            return;
        }

        String path = request.getServletPath();
        if (path != null && path.startsWith("/ws/")) {
            filterChain.doFilter(request, response);
            return;
        }

        if (path != null && path.startsWith("/admin/") && !CurrentUser.isAdministrator()) {
            forbidden(response, "Se requiere rol administrador");
            return;
        }

        String method = request.getMethod();
        if (path != null && path.startsWith("/support/markdown")
                && ("POST".equalsIgnoreCase(method) || "DELETE".equalsIgnoreCase(method))
                && CurrentUser.isSupport()) {
            forbidden(response, "El rol soporte no puede subir ni eliminar documentos de soporte");
            return;
        }

        filterChain.doFilter(request, response);
    }

    private static void forbidden(HttpServletResponse response, String msg) throws IOException {
        response.setStatus(HttpServletResponse.SC_FORBIDDEN);
        response.setCharacterEncoding(StandardCharsets.UTF_8.name());
        response.setContentType(MediaType.APPLICATION_JSON_VALUE);
        response.getWriter().write("{\"error\":\"" + escapeJson(msg) + "\"}");
    }

    private static String escapeJson(String s) {
        return s.replace("\\", "\\\\").replace("\"", "\\\"");
    }
}
