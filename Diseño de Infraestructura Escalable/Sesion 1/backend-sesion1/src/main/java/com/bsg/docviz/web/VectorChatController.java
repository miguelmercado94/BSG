package com.bsg.docviz.web;

import com.bsg.docviz.dto.VectorChatRequest;
import com.bsg.docviz.dto.VectorChatResponse;
import com.bsg.docviz.vector.VectorRagService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class VectorChatController {

    private final VectorRagService vectorRagService;

    public VectorChatController(VectorRagService vectorRagService) {
        this.vectorRagService = vectorRagService;
    }

    /**
     * RAG: pregunta sobre el repo indexado; LLM OpenAI (Spring AI).
     */
    @PostMapping("/vector/chat")
    public ResponseEntity<VectorChatResponse> chat(@Valid @RequestBody VectorChatRequest body) {
        return ResponseEntity.ok(vectorRagService.ask(body.getQuestion()));
    }
}
