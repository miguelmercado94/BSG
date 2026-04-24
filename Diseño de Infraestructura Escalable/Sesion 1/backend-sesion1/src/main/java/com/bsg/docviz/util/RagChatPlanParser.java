package com.bsg.docviz.util;

import com.bsg.docviz.dto.RagChatPlanFileRef;
import com.bsg.docviz.dto.RagChatPlanResponse;
import com.bsg.docviz.dto.RagChatPlanStep;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Optional;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Extrae y valida el JSON de plan / respuesta directa de la primera pasada del chat RAG.
 */
public final class RagChatPlanParser {

    private static final Logger log = LoggerFactory.getLogger(RagChatPlanParser.class);

    private static final Pattern FENCED_JSON =
            Pattern.compile("```(?:json)?\\s*([\\s\\S]*?)```", Pattern.CASE_INSENSITIVE);

    private RagChatPlanParser() {}

    /**
     * Intenta parsear la salida del modelo. Si no es JSON válido con {@code kind}, devuelve empty
     * (el caller puede tratar el texto como markdown legacy).
     */
    public static Optional<RagChatPlanResponse> tryParse(String raw, ObjectMapper mapper) {
        if (raw == null || raw.isBlank()) {
            return Optional.empty();
        }
        String payload = extractJsonPayload(raw.trim());
        if (payload == null || payload.isBlank()) {
            return Optional.empty();
        }
        try {
            JsonNode root = mapper.readTree(payload);
            if (root == null || !root.isObject()) {
                return Optional.empty();
            }
            String kind = text(root, "kind");
            if (kind == null || kind.isBlank()) {
                return Optional.empty();
            }
            String answer = text(root, "answer");
            JsonNode stepsNode = root.get("steps");
            List<RagChatPlanStep> steps = new ArrayList<>();
            if (stepsNode != null && stepsNode.isArray()) {
                for (JsonNode s : stepsNode) {
                    if (s == null || !s.isObject()) {
                        continue;
                    }
                    int ord = s.path("order").asInt(steps.size() + 1);
                    String summary = text(s, "summary");
                    if (summary == null) {
                        summary = "";
                    }
                    List<RagChatPlanFileRef> files = new ArrayList<>();
                    JsonNode filesNode = s.get("files");
                    if (filesNode != null && filesNode.isArray()) {
                        for (JsonNode f : filesNode) {
                            if (f == null || !f.isObject()) {
                                continue;
                            }
                            String path = text(f, "path");
                            String change = text(f, "change");
                            if (path != null && !path.isBlank()) {
                                files.add(new RagChatPlanFileRef(path.trim(), change != null ? change : ""));
                            }
                        }
                    }
                    steps.add(new RagChatPlanStep(ord, summary.trim(), files));
                }
            }
            steps.sort(Comparator.comparingInt(RagChatPlanStep::order));
            return Optional.of(new RagChatPlanResponse(kind.trim(), answer != null ? answer : "", steps));
        } catch (Exception e) {
            log.debug("RAG plan JSON no parseable: {}", e.toString());
            return Optional.empty();
        }
    }

    private static String text(JsonNode node, String field) {
        JsonNode n = node.get(field);
        if (n == null || n.isNull()) {
            return null;
        }
        if (n.isTextual()) {
            return n.asText();
        }
        return n.toString();
    }

    /** Primero bloque fenced; si no, primer objeto JSON entre { … }. */
    private static String extractJsonPayload(String raw) {
        Matcher m = FENCED_JSON.matcher(raw);
        if (m.find()) {
            return m.group(1).trim();
        }
        int start = raw.indexOf('{');
        int end = raw.lastIndexOf('}');
        if (start >= 0 && end > start) {
            return raw.substring(start, end + 1).trim();
        }
        return null;
    }
}
