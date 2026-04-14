package com.bsg.docviz.security;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.http.MediaType;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.nio.charset.StandardCharsets;

public class DocvizUserFilter extends OncePerRequestFilter {

    public static final String HEADER = "X-DocViz-User";

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
            throws ServletException, IOException {
        if ("OPTIONS".equalsIgnoreCase(request.getMethod())) {
            filterChain.doFilter(request, response);
            return;
        }

        // Comprobación de Firestore sin sesión DocViz (solo lectura de conectividad)
        if ("GET".equalsIgnoreCase(request.getMethod()) && "/firestore/health".equals(request.getRequestURI())) {
            filterChain.doFilter(request, response);
            return;
        }

        String raw = request.getHeader(HEADER);
        if (raw == null || raw.isBlank()) {
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            response.setCharacterEncoding(StandardCharsets.UTF_8.name());
            response.setContentType(MediaType.APPLICATION_JSON_VALUE);
            response.getWriter().write("{\"error\":\"Header " + HEADER + " is required\"}");
            return;
        }

        try {
            CurrentUser.set(UserIdSanitizer.forFilesystem(raw));
            filterChain.doFilter(request, response);
        } finally {
            CurrentUser.clear();
        }
    }
}
