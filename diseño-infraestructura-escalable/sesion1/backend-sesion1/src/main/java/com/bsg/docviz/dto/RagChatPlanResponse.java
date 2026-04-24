package com.bsg.docviz.dto;

import java.util.List;

/**
 * Primera respuesta del chat RAG: respuesta directa o plan estructurado (JSON).
 * Si es plan, el backend recorre {@link #steps()} y llama al LLM una vez por paso.
 */
public record RagChatPlanResponse(
        String kind,
        String answer,
        List<RagChatPlanStep> steps
) {
    public static final String KIND_DIRECT = "direct";
    public static final String KIND_PLAN = "plan";

    public RagChatPlanResponse {
        if (steps == null) {
            steps = List.of();
        }
    }

    public boolean isDirect() {
        return KIND_DIRECT.equalsIgnoreCase(kind != null ? kind.trim() : "");
    }

    public boolean isPlan() {
        return KIND_PLAN.equalsIgnoreCase(kind != null ? kind.trim() : "");
    }
}
