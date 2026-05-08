package com.bsg.docviz.security;

import com.bsg.docviz.context.DocvizCellContext;
import com.bsg.docviz.context.DocvizTaskContext;
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

    /** Opcional: código HU / tarea para S3 borradores y workarea en peticiones REST. */
    public static final String TASK_HU_HEADER = "X-DocViz-Task-Hu";

    /** Opcional: nombre de célula para las mismas rutas S3. */
    public static final String CELL_HEADER = "X-DocViz-Cell";

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
            throws ServletException, IOException {
        if ("OPTIONS".equalsIgnoreCase(request.getMethod())) {
            filterChain.doFilter(request, response);
            return;
        }

        String servletPath = request.getServletPath();

        // Comprobación de Firestore sin sesión DocViz (solo lectura de conectividad)
        if ("GET".equalsIgnoreCase(request.getMethod()) && "/firestore/health".equals(servletPath)) {
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
            String roleHeader = request.getHeader(CurrentUser.ROLE_HEADER);
            if (roleHeader == null || roleHeader.isBlank()) {
                CurrentUser.setRole(DocvizRoles.ADMINISTRATOR);
            } else {
                CurrentUser.setRole(roleHeader.trim());
            }
            String taskHu = request.getHeader(TASK_HU_HEADER);
            if (taskHu != null && !taskHu.isBlank()) {
                DocvizTaskContext.setTaskLabel(taskHu);
            }
            String cell = request.getHeader(CELL_HEADER);
            if (cell != null && !cell.isBlank()) {
                DocvizCellContext.setCellName(cell);
            }
            filterChain.doFilter(request, response);
        } finally {
            CurrentUser.clear();
            DocvizTaskContext.clear();
            DocvizCellContext.clear();
        }
    }
}
