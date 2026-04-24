package com.bsg.docviz.presentation.controller;

import com.bsg.docviz.context.ChatConversationIds;
import com.bsg.docviz.context.DocvizCellContext;
import com.bsg.docviz.context.DocvizChatContext;
import com.bsg.docviz.context.DocvizTaskContext;
import com.bsg.docviz.dto.RagChatPlanFileRef;
import com.bsg.docviz.dto.RagChatPlanResponse;
import com.bsg.docviz.dto.RagChatPlanStep;
import com.bsg.docviz.dto.RagPreparedContext;
import com.bsg.docviz.dto.WorkAreaProposalItemDto;
import com.bsg.docviz.dto.ws.RagChatClientMessage;
import com.bsg.docviz.dto.ws.RagChatServerMessage;
import com.bsg.docviz.security.DocvizRoles;
import com.bsg.docviz.service.ChatConversationPersistenceService;
import com.bsg.docviz.service.DomainTaskService;
import com.bsg.docviz.service.WorkAreaProposalEnrichmentService;
import com.bsg.docviz.security.CurrentUser;
import com.bsg.docviz.security.UserIdSanitizer;
import com.bsg.docviz.vector.VectorRagService;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.web.socket.CloseStatus;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;
import org.springframework.web.socket.handler.TextWebSocketHandler;

import com.bsg.docviz.util.RagChatPlanParser;
import com.bsg.docviz.util.WorkAreaProposalParser;
import com.bsg.docviz.util.WorkAreaProposalYamlParser;

import java.io.IOException;
import java.time.Duration;
import java.util.List;
import java.util.Locale;
import java.util.Optional;

/**
 * Chat RAG en streaming por WebSocket. Primera pasada: JSON {@code kind=direct|plan}; si es plan, pasos con archivos/cambios;
 * el backend recorre los pasos y llama al LLM una vez por paso, streameando al cliente.
 * <p>
 * Mensaje cliente (JSON): {@code {"question","user","role?","taskHuCode?","taskId?","conversationId?"}} —
 * Si hay {@code taskId} + {@code taskHuCode} y no hay {@code conversationId}, se usa el hilo principal (menor N en Firestore).
 */
@Component
public class RagChatWebSocketHandler extends TextWebSocketHandler {

    private static final Logger log = LoggerFactory.getLogger(RagChatWebSocketHandler.class);

    private static final Duration TASK_STEP_TIMEOUT = Duration.ofMinutes(3);

    private final VectorRagService vectorRagService;
    private final ObjectMapper objectMapper;
    private final WorkAreaProposalEnrichmentService workAreaProposalEnrichmentService;
    private final ChatConversationPersistenceService chatConversationPersistence;

    public RagChatWebSocketHandler(
            VectorRagService vectorRagService,
            ObjectMapper objectMapper,
            WorkAreaProposalEnrichmentService workAreaProposalEnrichmentService,
            ChatConversationPersistenceService chatConversationPersistence) {
        this.vectorRagService = vectorRagService;
        this.objectMapper = objectMapper;
        this.workAreaProposalEnrichmentService = workAreaProposalEnrichmentService;
        this.chatConversationPersistence = chatConversationPersistence;
    }

    /**
     * Saludos o mensajes triviales: no forzar JSON con plan/propuestas; el modelo responde en texto (RAG normal).
     */
    private static boolean isCasualConversation(String raw) {
        if (raw == null) {
            return false;
        }
        String s = raw.trim().toLowerCase(Locale.ROOT);
        if (s.length() > 120) {
            return false;
        }
        if (s.contains("@[")) {
            return false;
        }
        if (s.matches("^(hola|hi|hello|hey)(\\s*!*)?$")) {
            return true;
        }
        if (s.matches("^(buenos días|buenas tardes|buenas noches|buenas)(\\s*!*)?$")) {
            return true;
        }
        if (s.matches("^(gracias|thanks|thank you)(\\s*!*)?$")) {
            return true;
        }
        if (s.matches("^(ok|vale|genial|perfecto|de acuerdo)(\\.?\\s*!*)?$")) {
            return true;
        }
        return false;
    }

    /**
     * Aplica el prefijo de instrucción del chat RAG. Si el cliente envía el prefijo nuevo o el legado de
     * {@link DomainTaskService#PROMPT_PREFIX} (continuar tarea), no se duplica.
     */
    private static String ensureRagChatPrefix(String rawQuestion) {
        String q = rawQuestion.trim();
        String rag = DomainTaskService.RAG_CHAT_PROMPT_PREFIX;
        if (q.startsWith(rag)) {
            return q;
        }
        String legacy = DomainTaskService.PROMPT_PREFIX;
        if (q.startsWith(legacy)) {
            return rag + q.substring(legacy.length()).trim();
        }
        return rag + q;
    }

    private static String formatPlanAsMarkdown(RagChatPlanResponse r) {
        StringBuilder sb = new StringBuilder();
        sb.append("## Plan\n\n");
        int i = 1;
        for (RagChatPlanStep st : r.steps()) {
            sb.append(i++).append(". **").append(st.summary()).append("**\n");
            for (RagChatPlanFileRef fr : st.files()) {
                sb.append("   - `").append(fr.path()).append("`: ").append(fr.change()).append("\n");
            }
            sb.append("\n");
        }
        return sb.toString();
    }

    /** Un paso del plan JSON: incluye resumen del paso y archivos/cambios sin acumular salidas previas. */
    private static String buildSingleStepPromptFromPlan(
            String rawQuestion, List<RagChatPlanStep> planSteps, int stepIndex) {
        RagChatPlanStep current = planSteps.get(stepIndex);
        StringBuilder sb = new StringBuilder();
        sb.append("Resuelve únicamente el paso ")
                .append(stepIndex + 1)
                .append(" de ")
                .append(planSteps.size())
                .append(". Usa el contexto RAG del repositorio si aplica.\n\n");
        sb.append("Enunciado:\n").append(rawQuestion.trim()).append("\n\n");
        sb.append("Plan de referencia:\n");
        for (int j = 0; j < planSteps.size(); j++) {
            RagChatPlanStep st = planSteps.get(j);
            sb.append(j + 1).append(". ").append(st.summary()).append("\n");
            for (RagChatPlanFileRef fr : st.files()) {
                sb.append("   - `").append(fr.path()).append("`: ").append(fr.change()).append("\n");
            }
        }
        sb.append("\nDesarrolla en detalle solo el paso ").append(stepIndex + 1).append(": ").append(current.summary());
        if (!current.files().isEmpty()) {
            sb.append("\n\nArchivos de este paso:\n");
            for (RagChatPlanFileRef fr : current.files()) {
                sb.append("- `").append(fr.path()).append("`: ").append(fr.change()).append("\n");
            }
        }
        return sb.toString();
    }

    /** Fallback si la primera respuesta no era JSON pero tenía líneas numeradas. */
    private static String buildSingleStepPromptLegacy(String rawQuestion, List<String> stepTitles, int stepIndex) {
        StringBuilder sb = new StringBuilder();
        sb.append("Resuelve únicamente el paso ")
                .append(stepIndex + 1)
                .append(" de ")
                .append(stepTitles.size())
                .append(". Sé concreto y usa el contexto del repositorio (RAG) si aplica.\n\n");
        sb.append("Enunciado:\n").append(rawQuestion.trim()).append("\n\n");
        sb.append("Plan de referencia (solo títulos):\n");
        for (int j = 0; j < stepTitles.size(); j++) {
            sb.append(j + 1).append(". ").append(stepTitles.get(j)).append('\n');
        }
        sb.append("\nDesarrolla solo el paso ").append(stepIndex + 1).append(": ").append(stepTitles.get(stepIndex));
        return sb.toString();
    }

    private void streamTextAsDeltas(WebSocketSession session, String text) throws IOException {
        if (text == null || text.isEmpty()) {
            return;
        }
        final int chunkSize = 480;
        for (int i = 0; i < text.length(); i += chunkSize) {
            int end = Math.min(i + chunkSize, text.length());
            sendJson(session, RagChatServerMessage.Delta.of(text.substring(i, end)));
        }
    }

    @Override
    public void afterConnectionEstablished(WebSocketSession session) {
        log.debug("WS rag-chat conectado: {}", session.getId());
    }

    @Override
    protected void handleTextMessage(WebSocketSession session, TextMessage message) throws Exception {
        RagChatClientMessage in;
        try {
            in = objectMapper.readValue(message.getPayload(), RagChatClientMessage.class);
        } catch (IOException e) {
            sendJson(session, RagChatServerMessage.Error.of("JSON inválido"));
            return;
        }
        String rawQuestion = in.getQuestion() != null ? in.getQuestion().trim() : "";
        String rawUser = in.getUser() != null ? in.getUser().trim() : "";
        if (rawQuestion.isEmpty()) {
            sendJson(session, RagChatServerMessage.Error.of("question es obligatoria"));
            return;
        }
        if (rawUser.isEmpty()) {
            sendJson(session, RagChatServerMessage.Error.of("user es obligatorio"));
            return;
        }

        String roleRaw = in.getRole() != null ? in.getRole().trim() : "";
        CurrentUser.set(UserIdSanitizer.forFilesystem(rawUser));
        if (!roleRaw.isEmpty()
                && (DocvizRoles.ADMINISTRATOR.equals(roleRaw) || DocvizRoles.SUPPORT.equals(roleRaw))) {
            CurrentUser.setRole(roleRaw);
        }
        String taskHuRaw = in.getTaskHuCode() != null ? in.getTaskHuCode().trim() : "";
        if (!taskHuRaw.isEmpty()) {
            DocvizTaskContext.setTaskLabel(taskHuRaw);
        }
        String cellRaw = in.getCellName() != null ? in.getCellName().trim() : "";
        if (!cellRaw.isEmpty()) {
            DocvizCellContext.setCellName(cellRaw);
        }
        long taskIdWs = in.getTaskId() != null ? in.getTaskId() : 0L;
        String conversationIdRaw = in.getConversationId() != null ? in.getConversationId().trim() : "";
        String cellForChat = cellRaw.isEmpty() ? null : cellRaw;
        String conversationId;
        if (!conversationIdRaw.isEmpty()) {
            conversationId = conversationIdRaw;
        } else if (taskIdWs > 0L && !taskHuRaw.isEmpty()) {
            conversationId = chatConversationPersistence.findPrimaryConversationId(rawUser, taskIdWs, taskHuRaw, cellForChat);
        } else if (!taskHuRaw.isEmpty()) {
            conversationId = ChatConversationIds.forUserCellHuTaskIdAndThread(rawUser, cellForChat, taskHuRaw, taskIdWs, 0);
        } else {
            conversationId = UserIdSanitizer.forFilesystem(rawUser) + "_default_0";
        }
        DocvizChatContext.setConversationId(conversationId);
        try {
            String planningQuery =
                    isCasualConversation(rawQuestion) ? rawQuestion.trim() : ensureRagChatPrefix(rawQuestion);
            RagPreparedContext ctx = vectorRagService.prepareRagOrThrow(planningQuery, rawQuestion);
            sendJson(session, RagChatServerMessage.Start.of(ctx.sources()));

            StringBuilder firstPassBuf = new StringBuilder();
            for (String chunk : vectorRagService.streamAnswer(ctx).toIterable()) {
                if (chunk != null) {
                    firstPassBuf.append(chunk);
                }
            }

            Optional<RagChatPlanResponse> planOpt = RagChatPlanParser.tryParse(firstPassBuf.toString(), objectMapper);
            StringBuilder persistBuf = new StringBuilder();

            if (planOpt.isPresent()) {
                RagChatPlanResponse r = planOpt.get();
                // Conservar la primera respuesta cruda: puede ir JSON de plan/kind o propuestas JSON legacy; propuestas YAML van en ```yaml.
                // Antes solo se persistía answer en direct y se perdían las propuestas.
                persistBuf.append(firstPassBuf);
                if (r.isDirect()) {
                    String ans = r.answer() != null ? r.answer() : "";
                    streamTextAsDeltas(session, ans);
                } else if (r.isPlan() && !r.steps().isEmpty()) {
                    persistBuf.append("\n\n");
                    String planMd = formatPlanAsMarkdown(r);
                    streamTextAsDeltas(session, planMd);
                    persistBuf.append(planMd);
                    sendJson(
                            session,
                            RagChatServerMessage.Delta.of(
                                    "\n\n--- Ejecución por pasos (una llamada al modelo por paso) ---\n\n"));
                    persistBuf.append("\n\n--- Ejecución por pasos ---\n\n");
                    for (int i = 0; i < r.steps().size(); i++) {
                        String stepQ = buildSingleStepPromptFromPlan(rawQuestion, r.steps(), i);
                        RagPreparedContext stepCtx = vectorRagService.prepareRagOrThrow(stepQ, null);
                        sendJson(session, RagChatServerMessage.Start.of(stepCtx.sources()));
                        for (String chunk : vectorRagService.streamAnswer(stepCtx, TASK_STEP_TIMEOUT).toIterable()) {
                            if (chunk != null) {
                                persistBuf.append(chunk);
                                sendJson(session, RagChatServerMessage.Delta.of(chunk));
                            }
                        }
                    }
                } else {
                    log.debug("WS rag-chat: JSON plan sin pasos; se muestra respuesta cruda.");
                    streamTextAsDeltas(session, firstPassBuf.toString());
                    persistBuf.append(firstPassBuf);
                }
            } else {
                log.debug("WS rag-chat: primera respuesta no es JSON de plan; fallback a texto y pasos numerados si existen.");
                streamTextAsDeltas(session, firstPassBuf.toString());
                persistBuf.append(firstPassBuf);
                List<String> legacySteps = VectorRagService.parsePlanSteps(firstPassBuf.toString());
                if (!legacySteps.isEmpty()) {
                    sendJson(
                            session,
                            RagChatServerMessage.Delta.of(
                                    "\n\n--- Desarrollo por pasos (lista numerada detectada en texto) ---\n\n"));
                    persistBuf.append("\n\n--- Desarrollo por pasos (legacy) ---\n\n");
                    for (int i = 0; i < legacySteps.size(); i++) {
                        String stepQ = buildSingleStepPromptLegacy(rawQuestion, legacySteps, i);
                        RagPreparedContext stepCtx = vectorRagService.prepareRagOrThrow(stepQ, null);
                        sendJson(session, RagChatServerMessage.Start.of(stepCtx.sources()));
                        for (String chunk : vectorRagService.streamAnswer(stepCtx, TASK_STEP_TIMEOUT).toIterable()) {
                            if (chunk != null) {
                                persistBuf.append(chunk);
                                sendJson(session, RagChatServerMessage.Delta.of(chunk));
                            }
                        }
                    }
                }
            }

            String fullStr = persistBuf.toString();
            List<WorkAreaProposalItemDto> proposals = WorkAreaProposalParser.parseProposals(fullStr, objectMapper);
            log.info("WS rag-chat: tras parsear respuesta acumulada ({} chars) → {} propuesta(s)", fullStr.length(), proposals.size());
            if (!proposals.isEmpty()) {
                workAreaProposalEnrichmentService.enrichFromRepository(proposals);
            }
            String stripped = WorkAreaProposalYamlParser.stripFencedYamlBlocks(fullStr);
            stripped = WorkAreaProposalParser.stripFencedJsonBlocks(stripped);
            String toPersist = stripped.isBlank() ? fullStr : stripped;

            if (!proposals.isEmpty()) {
                sendJson(session, RagChatServerMessage.Proposals.of(proposals));
            }

            sendJson(session, RagChatServerMessage.Done.instance());
            vectorRagService.persistRagTurn(ctx, toPersist, rawQuestion);
        } catch (ResponseStatusException ex) {
            String msg = ex.getReason() != null ? ex.getReason() : ex.getStatusCode().toString();
            sendJson(session, RagChatServerMessage.Error.of(msg));
        } catch (IllegalStateException ex) {
            sendJson(
                    session,
                    RagChatServerMessage.Error.of(ex.getMessage() != null ? ex.getMessage() : "estado inválido"));
        } catch (RuntimeException ex) {
            // No asumir IOException en la causa = fallo al escribir al WebSocket; suele ser p. ej.
            // ResourceAccessException (Ollama/embeddings) con causa SocketException.
            log.warn("WS rag-chat", ex);
            String msg = errorMessageForClient(ex);
            try {
                sendJson(session, RagChatServerMessage.Error.of(msg));
            } catch (IOException sendErr) {
                log.warn("WS rag-chat: no se pudo enviar mensaje de error al cliente: {}", sendErr.toString());
            }
        } finally {
            CurrentUser.clear();
            DocvizTaskContext.clear();
            DocvizCellContext.clear();
            DocvizChatContext.clear();
        }
    }

    @Override
    public void handleTransportError(WebSocketSession session, Throwable exception) {
        log.warn("WS rag-chat error de transporte: {}", exception.toString());
    }

    @Override
    public void afterConnectionClosed(WebSocketSession session, CloseStatus status) {
        log.debug("WS rag-chat cerrado: {} {}", session.getId(), status);
    }

    private void sendJson(WebSocketSession session, Object body) throws IOException {
        String json = objectMapper.writeValueAsString(body);
        synchronized (session) {
            if (session.isOpen()) {
                session.sendMessage(new TextMessage(json));
            }
        }
    }

    /** Mensaje útil en la UI; prioriza el texto de la excepción (p. ej. fallo a Ollama), no un genérico. */
    private static String errorMessageForClient(RuntimeException ex) {
        String m = ex.getMessage();
        if (m != null && !m.isBlank()) {
            return m;
        }
        Throwable c = ex.getCause();
        if (c != null && c.getMessage() != null && !c.getMessage().isBlank()) {
            return c.getMessage();
        }
        return "error";
    }
}
