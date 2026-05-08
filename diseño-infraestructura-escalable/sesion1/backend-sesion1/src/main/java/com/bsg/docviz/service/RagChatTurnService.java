package com.bsg.docviz.service;

import com.bsg.docviz.context.ChatConversationIds;
import com.bsg.docviz.context.DocvizCellContext;
import com.bsg.docviz.context.DocvizChatContext;
import com.bsg.docviz.context.DocvizTaskContext;
import com.bsg.docviz.dto.RagChatPlanFileRef;
import com.bsg.docviz.dto.RagChatPlanResponse;
import com.bsg.docviz.dto.RagChatPlanStep;
import com.bsg.docviz.dto.RagPreparedContext;
import com.bsg.docviz.dto.WorkAreaProposalItemDto;
import com.bsg.docviz.dto.RagChatClientMessage;
import com.bsg.docviz.security.DocvizRoles;
import com.bsg.docviz.security.CurrentUser;
import com.bsg.docviz.security.UserIdSanitizer;
import com.bsg.docviz.util.RagChatPlanParser;
import com.bsg.docviz.util.WorkAreaProposalParser;
import com.bsg.docviz.util.WorkAreaProposalYamlParser;
import com.bsg.docviz.vector.VectorRagService;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClientResponseException;
import org.springframework.web.server.ResponseStatusException;

import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Optional;

/** Lógica del chat RAG invocada desde POST {@code /vector/chat/rag-turn}. */
@Service
public class RagChatTurnService {

    private static final Logger log = LoggerFactory.getLogger(RagChatTurnService.class);

    private static final Duration TASK_STEP_TIMEOUT = Duration.ofMinutes(3);

    private static final int DELTA_CHUNK = 480;

    private final VectorRagService vectorRagService;
    private final ObjectMapper objectMapper;
    private final WorkAreaProposalEnrichmentService workAreaProposalEnrichmentService;
    private final ChatConversationPersistenceService chatConversationPersistence;

    public RagChatTurnService(
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
     * Ejecuta un turno de chat RAG y envía fragmentos al sink. Cierra contexto HTTP en {@code finally} del llamador
     * si aplica; aquí se limpia {@link CurrentUser} / contextos de tarea.
     */
    public void executeTurn(RagChatClientMessage in, RagChatStreamSink sink) {
        String rawQuestion = in.getQuestion() != null ? in.getQuestion().trim() : "";
        String rawUser = in.getUser() != null ? in.getUser().trim() : "";
        if (rawQuestion.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "question es obligatoria");
        }
        if (rawUser.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "user es obligatorio");
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
            sink.onStart(ctx.sources());

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
                persistBuf.append(firstPassBuf);
                if (r.isDirect()) {
                    String ans = r.answer() != null ? r.answer() : "";
                    streamTextAsDeltas(sink, ans);
                } else if (r.isPlan() && !r.steps().isEmpty()) {
                    persistBuf.append("\n\n");
                    String planMd = formatPlanAsMarkdown(r);
                    streamTextAsDeltas(sink, planMd);
                    persistBuf.append(planMd);
                    sink.onDelta("\n\n--- Ejecución por pasos (una llamada al modelo por paso) ---\n\n");
                    persistBuf.append("\n\n--- Ejecución por pasos ---\n\n");
                    for (int i = 0; i < r.steps().size(); i++) {
                        String stepQ = buildSingleStepPromptFromPlan(rawQuestion, r.steps(), i);
                        RagPreparedContext stepCtx = vectorRagService.prepareRagOrThrow(stepQ, null);
                        sink.onStart(stepCtx.sources());
                        for (String chunk : vectorRagService.streamAnswer(stepCtx, TASK_STEP_TIMEOUT).toIterable()) {
                            if (chunk != null) {
                                persistBuf.append(chunk);
                                sink.onDelta(chunk);
                            }
                        }
                    }
                } else {
                    log.debug("rag-chat: JSON plan sin pasos; se muestra respuesta cruda.");
                    streamTextAsDeltas(sink, firstPassBuf.toString());
                    persistBuf.append(firstPassBuf);
                }
            } else {
                log.debug("rag-chat: primera respuesta no es JSON de plan; fallback a texto y pasos numerados si existen.");
                streamTextAsDeltas(sink, firstPassBuf.toString());
                persistBuf.append(firstPassBuf);
                List<String> legacySteps = VectorRagService.parsePlanSteps(firstPassBuf.toString());
                if (!legacySteps.isEmpty()) {
                    sink.onDelta("\n\n--- Desarrollo por pasos (lista numerada detectada en texto) ---\n\n");
                    persistBuf.append("\n\n--- Desarrollo por pasos (legacy) ---\n\n");
                    for (int i = 0; i < legacySteps.size(); i++) {
                        String stepQ = buildSingleStepPromptLegacy(rawQuestion, legacySteps, i);
                        RagPreparedContext stepCtx = vectorRagService.prepareRagOrThrow(stepQ, null);
                        sink.onStart(stepCtx.sources());
                        for (String chunk : vectorRagService.streamAnswer(stepCtx, TASK_STEP_TIMEOUT).toIterable()) {
                            if (chunk != null) {
                                persistBuf.append(chunk);
                                sink.onDelta(chunk);
                            }
                        }
                    }
                }
            }

            String fullStr = persistBuf.toString();
            List<WorkAreaProposalItemDto> proposals = WorkAreaProposalParser.parseProposals(fullStr, objectMapper);
            log.info(
                    "rag-chat: tras parsear respuesta acumulada ({} chars) → {} propuesta(s)",
                    fullStr.length(),
                    proposals.size());
            if (!proposals.isEmpty()) {
                workAreaProposalEnrichmentService.enrichFromRepository(proposals);
            }
            String stripped = WorkAreaProposalYamlParser.stripFencedYamlBlocks(fullStr);
            stripped = WorkAreaProposalParser.stripFencedJsonBlocks(stripped);
            String toPersist = stripped.isBlank() ? fullStr : stripped;

            if (!proposals.isEmpty()) {
                sink.onProposals(proposals);
            }

            sink.onDone();
            vectorRagService.persistRagTurn(ctx, toPersist, rawQuestion);
        } catch (Throwable ex) {
            logOpenAiUpstreamFailure(ex);
            if (ex instanceof RuntimeException re) {
                throw re;
            }
            throw new RuntimeException(ex);
        } finally {
            CurrentUser.clear();
            DocvizTaskContext.clear();
            DocvizCellContext.clear();
            DocvizChatContext.clear();
        }
    }

    /** En CloudWatch aparece el JSON de error de OpenAI (p. ej. modelo, contexto, parámetro inválido). */
    private static void logOpenAiUpstreamFailure(Throwable ex) {
        for (Throwable t = ex; t != null; t = t.getCause()) {
            if (t instanceof WebClientResponseException w) {
                String body = w.getResponseBodyAsString(StandardCharsets.UTF_8);
                if (body != null) {
                    body = body.replace('\r', ' ').replace('\n', ' ');
                }
                log.error(
                        "OpenAI HTTP {} — body: {}",
                        w.getStatusCode().value(),
                        body != null && body.length() > 4000 ? body.substring(0, 4000) + "…" : body);
                return;
            }
        }
    }

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

    private static void streamTextAsDeltas(RagChatStreamSink sink, String text) {
        if (text == null || text.isEmpty()) {
            return;
        }
        for (int i = 0; i < text.length(); i += DELTA_CHUNK) {
            int end = Math.min(i + DELTA_CHUNK, text.length());
            sink.onDelta(text.substring(i, end));
        }
    }

    /** Expone fuentes acumuladas y texto completo para REST sin duplicar la lógica del modelo. */
    public static final class CollectingSink implements RagChatStreamSink {

        private final LinkedHashSet<String> allSources = new LinkedHashSet<>();
        private final StringBuilder fullText = new StringBuilder();
        private List<WorkAreaProposalItemDto> proposals = List.of();

        @Override
        public void onStart(List<String> sources) {
            if (sources != null) {
                allSources.addAll(sources);
            }
        }

        @Override
        public void onDelta(String text) {
            if (text != null) {
                fullText.append(text);
            }
        }

        @Override
        public void onProposals(List<WorkAreaProposalItemDto> proposals) {
            this.proposals = proposals != null ? new ArrayList<>(proposals) : List.of();
        }

        @Override
        public void onDone() {
            // no-op
        }

        public List<String> getSources() {
            return new ArrayList<>(allSources);
        }

        public String getAnswer() {
            return fullText.toString();
        }

        public List<WorkAreaProposalItemDto> getProposals() {
            return proposals;
        }
    }
}
