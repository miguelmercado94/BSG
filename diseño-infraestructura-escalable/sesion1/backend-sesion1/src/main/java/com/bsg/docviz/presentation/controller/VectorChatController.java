package com.bsg.docviz.presentation.controller;

import com.bsg.docviz.dto.ChatHistoryEntryDto;
import com.bsg.docviz.dto.RagChatTurnHttpRequest;
import com.bsg.docviz.dto.RagChatTurnResponse;
import com.bsg.docviz.dto.VectorChatRequest;
import com.bsg.docviz.dto.VectorChatResponse;
import com.bsg.docviz.dto.RagChatClientMessage;
import com.bsg.docviz.security.CurrentUser;
import com.bsg.docviz.service.ChatConversationPersistenceService;
import com.bsg.docviz.service.RagChatTurnService;
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
    private final RagChatTurnService ragChatTurnService;

    public VectorChatController(
            VectorRagService vectorRagService,
            ChatConversationPersistenceService chatConversationPersistence,
            RagChatTurnService ragChatTurnService) {
        this.vectorRagService = vectorRagService;
        this.chatConversationPersistence = chatConversationPersistence;
        this.ragChatTurnService = ragChatTurnService;
    }

    /**
     * RAG: pregunta sobre el repo indexado; LLM OpenAI (Spring AI).
     */
    @PostMapping("/vector/chat")
    public ResponseEntity<VectorChatResponse> chat(@Valid @RequestBody VectorChatRequest body) {
        return ResponseEntity.ok(vectorRagService.ask(body.getQuestion()));
    }

    /** Chat RAG por REST: una respuesta JSON con la respuesta completa (chunks simulados en el cliente). */
    @PostMapping("/vector/chat/rag-turn")
    public ResponseEntity<RagChatTurnResponse> ragTurn(@Valid @RequestBody RagChatTurnHttpRequest body) {
        RagChatClientMessage in = new RagChatClientMessage();
        in.setQuestion(body.getQuestion());
        in.setUser(CurrentUser.require());
        CurrentUser.role().ifPresent(in::setRole);
        if (body.getTaskHuCode() != null && !body.getTaskHuCode().isBlank()) {
            in.setTaskHuCode(body.getTaskHuCode().trim());
        }
        if (body.getTaskId() != null) {
            in.setTaskIdFlexible(body.getTaskId());
        }
        if (body.getConversationId() != null && !body.getConversationId().isBlank()) {
            in.setConversationId(body.getConversationId().trim());
        }
        if (body.getCellName() != null && !body.getCellName().isBlank()) {
            in.setCellName(body.getCellName().trim());
        }

        RagChatTurnService.CollectingSink sink = new RagChatTurnService.CollectingSink();
        ragChatTurnService.executeTurn(in, sink);

        RagChatTurnResponse out = new RagChatTurnResponse();
        out.setAnswer(sink.getAnswer());
        out.setSources(sink.getSources());
        out.setProposals(sink.getProposals());
        return ResponseEntity.ok(out);
    }

    /**
     * Historial persistido (Firestore): {@code users/{userId}/messages}, mismo usuario que {@code X-DocViz-User}.
     */
    @GetMapping("/vector/chat/history")
    public ResponseEntity<List<ChatHistoryEntryDto>> history(
            @RequestParam(name = "limit", defaultValue = "40") int limit,
            @RequestParam(name = "conversationId", required = false) String conversationId,
            @RequestParam(name = "taskId", required = false) Long taskId,
            @RequestParam(name = "huCode", required = false) String huCode,
            @RequestParam(name = "cellName", required = false) String cellName) {
        int lim = Math.min(Math.max(1, limit), 100);
        if (taskId != null && taskId > 0 && huCode != null && !huCode.isBlank()) {
            ChatConversationPersistenceService.ResolvedChatHistory r =
                    chatConversationPersistence.loadRecentTurnsForTaskResolved(
                            CurrentUser.require(), lim, taskId, huCode.trim(), cellName != null ? cellName.trim() : null);
            return ResponseEntity.ok()
                    .header("X-DocViz-Resolved-Conversation-Id", r.resolvedConversationId())
                    .body(r.entries());
        }
        return ResponseEntity.ok(chatConversationPersistence.loadRecentTurns(CurrentUser.require(), lim, conversationId));
    }
}
