package com.bsg.docviz.web;

import com.bsg.docviz.dto.ChatHistoryEntryDto;
import com.bsg.docviz.dto.VectorChatRequest;
import com.bsg.docviz.dto.VectorChatResponse;
import com.bsg.docviz.security.CurrentUser;
import com.bsg.docviz.service.ChatConversationPersistenceService;
import com.bsg.docviz.vector.VectorRagService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
public class VectorChatController {

    private final VectorRagService vectorRagService;
    private final ChatConversationPersistenceService chatConversationPersistence;

    public VectorChatController(
            VectorRagService vectorRagService,
            ChatConversationPersistenceService chatConversationPersistence) {
        this.vectorRagService = vectorRagService;
        this.chatConversationPersistence = chatConversationPersistence;
    }

    /**
     * RAG: pregunta sobre el repo indexado; LLM OpenAI (Spring AI).
     */
    @PostMapping("/vector/chat")
    public ResponseEntity<VectorChatResponse> chat(@Valid @RequestBody VectorChatRequest body) {
        return ResponseEntity.ok(vectorRagService.ask(body.getQuestion()));
    }

    /**
     * Historial persistido (Firestore): {@code users/{userId}/messages}, mismo usuario que {@code X-DocViz-User}.
     */
    @GetMapping("/vector/chat/history")
    public ResponseEntity<List<ChatHistoryEntryDto>> history(
            @RequestParam(name = "limit", defaultValue = "40") int limit) {
        int lim = Math.min(Math.max(1, limit), 100);
        return ResponseEntity.ok(chatConversationPersistence.loadRecentTurns(CurrentUser.require(), lim));
    }
}
