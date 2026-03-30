package com.bsg.docviz.web;

import com.bsg.docviz.dto.IngestProgressDto;
import com.bsg.docviz.dto.VectorIngestResponse;
import com.bsg.docviz.security.CurrentUser;
import com.bsg.docviz.vector.VectorIngestService;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.servlet.mvc.method.annotation.StreamingResponseBody;

import java.io.IOException;
import java.io.OutputStreamWriter;
import java.io.UncheckedIOException;
import java.io.Writer;
import java.nio.charset.StandardCharsets;

@RestController
public class VectorIngestController {

    private final VectorIngestService vectorIngestService;
    private final ObjectMapper objectMapper;

    public VectorIngestController(VectorIngestService vectorIngestService, ObjectMapper objectMapper) {
        this.vectorIngestService = vectorIngestService;
        this.objectMapper = objectMapper;
    }

    /**
     * Indexa el repositorio conectado en Pinecone (embed + upsert).
     */
    @PostMapping("/vector/ingest")
    public ResponseEntity<VectorIngestResponse> ingest() {
        return ResponseEntity.ok(vectorIngestService.ingestAll());
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
                        vectorIngestService.ingestAll(ev -> {
                            try {
                                w.write(objectMapper.writeValueAsString(ev));
                                w.write("\n");
                                w.flush();
                            } catch (IOException e) {
                                throw new UncheckedIOException(e);
                            }
                        });
                    } catch (Exception e) {
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
