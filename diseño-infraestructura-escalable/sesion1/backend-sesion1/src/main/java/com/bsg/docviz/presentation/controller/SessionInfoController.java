package com.bsg.docviz.presentation.controller;

import com.bsg.docviz.dto.VectorNamespaceResponse;
import com.bsg.docviz.vector.VectorIngestService;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

@RestController
@RequestMapping("/session")
public class SessionInfoController {

    private final VectorIngestService vectorIngestService;

    public SessionInfoController(VectorIngestService vectorIngestService) {
        this.vectorIngestService = vectorIngestService;
    }

    /**
     * Namespace vectorial actual (tras conectar Git). El administrador puede copiarlo al configurar
     * {@code vectorNamespace} en el repositorio de la celda para alinear soporte e índices .md.
     */
    @GetMapping("/vector-namespace")
    public VectorNamespaceResponse vectorNamespace() {
        try {
            return new VectorNamespaceResponse(vectorIngestService.currentNamespace());
        } catch (Exception e) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Conecta un repositorio antes de consultar el namespace");
        }
    }
}
