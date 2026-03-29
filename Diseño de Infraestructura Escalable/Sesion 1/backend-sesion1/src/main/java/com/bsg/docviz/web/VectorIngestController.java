package com.bsg.docviz.web;

import com.bsg.docviz.dto.VectorIngestResponse;
import com.bsg.docviz.vector.VectorIngestService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class VectorIngestController {

    private final VectorIngestService vectorIngestService;

    public VectorIngestController(VectorIngestService vectorIngestService) {
        this.vectorIngestService = vectorIngestService;
    }

    /**
     * Indexa el repositorio conectado en Pinecone (embed + upsert).
     */
    @PostMapping("/vector/ingest")
    public ResponseEntity<VectorIngestResponse> ingest() {
        return ResponseEntity.ok(vectorIngestService.ingestAll());
    }
}
