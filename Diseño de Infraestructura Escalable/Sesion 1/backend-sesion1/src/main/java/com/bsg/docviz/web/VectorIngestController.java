package com.bsg.docviz.web;

import com.bsg.docviz.dto.IngestProgressDto;
import com.bsg.docviz.dto.VectorIngestResponse;
import com.bsg.docviz.security.CurrentUser;
import com.bsg.docviz.vector.VectorIngestService;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.servlet.mvc.method.annotation.StreamingResponseBody;

import java.io.IOException;
import java.io.OutputStreamWriter;
import java.io.UncheckedIOException;
import java.io.Writer;
import java.nio.charset.StandardCharsets;
import java.util.Map;

@RestController
public class VectorIngestController {

    private static final Logger log = LoggerFactory.getLogger(VectorIngestController.class);

    private final VectorIngestService vectorIngestService;
    private final ObjectMapper objectMapper;

    public VectorIngestController(VectorIngestService vectorIngestService, ObjectMapper objectMapper) {
        this.vectorIngestService = vectorIngestService;
        this.objectMapper = objectMapper;
    }

    /**
     * Indexa el repositorio conectado (embed + upsert en el almacén vectorial configurado, p. ej. pgvector).
     */
    @PostMapping("/vector/ingest")
    public ResponseEntity<VectorIngestResponse> ingest() {
        return ResponseEntity.ok(vectorIngestService.ingestAll());
    }

    /**
     * Elimina todos los chunks vectoriales del namespace del repositorio conectado (pgvector: filas en
     * {@code docviz_vector_chunk}; Pinecone: delete por namespace). Misma idea que vaciar el índice antes de re-indexar.
     */
    @DeleteMapping("/vector/index")
    public ResponseEntity<Map<String, Object>> clearIndex() {
        String ns = vectorIngestService.clearCurrentNamespaceIndex();
        return ResponseEntity.ok(Map.of("namespace", ns, "cleared", Boolean.TRUE));
    }

    /**
     * Misma ingesta que {@code /vector/ingest}, pero emite líneas NDJSON con progreso
     * (START, FILE, PROGRESS, DONE o ERROR).
     */
    @PostMapping(value = "/vector/ingest/stream", produces = "application/x-ndjson")
    public ResponseEntity<StreamingResponseBody> ingestStream() {
        // El filtro limpia CurrentUser al terminar el chain; el cuerpo del stream se ejecuta después.
        final String userId = CurrentUser.require();
        StreamingResponseBody body = outputStream -> {
            CurrentUser.set(userId);
            try {
                try (Writer w = new OutputStreamWriter(outputStream, StandardCharsets.UTF_8)) {
                    try {
                        log.info("POST /vector/ingest/stream iniciado (usuario={})", userId);
                        vectorIngestService.ingestAll(ev -> {
                            try {
                                w.write(objectMapper.writeValueAsString(ev));
                                w.write("\n");
                                w.flush();
                            } catch (IOException e) {
                                throw new UncheckedIOException(e);
                            }
                        });
                        log.info("POST /vector/ingest/stream completado (usuario={})", userId);
                    } catch (Exception e) {
                        log.error(
                                "POST /vector/ingest/stream falló: {} — {}",
                                e.getClass().getName(),
                                e.getMessage() != null ? e.getMessage() : "(sin mensaje)",
                                e);
                        String msg = e.getMessage() != null ? e.getMessage() : e.toString();
                        try {
                            w.write(objectMapper.writeValueAsString(IngestProgressDto.error(msg)));
                            w.write("\n");
                            w.flush();
                        } catch (IOException ignored) {
                            // cliente cerró
                        }
                    }
                }
            } finally {
                CurrentUser.clear();
            }
        };
        return ResponseEntity.ok()
                .contentType(MediaType.parseMediaType("application/x-ndjson"))
                .body(body);
    }
}
