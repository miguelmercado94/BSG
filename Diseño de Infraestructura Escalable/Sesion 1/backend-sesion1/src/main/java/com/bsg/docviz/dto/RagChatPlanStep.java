package com.bsg.docviz.dto;

import java.util.List;

/** Un paso del plan JSON: resumen y, si aplica, archivos a tocar con descripción del cambio. */
public record RagChatPlanStep(int order, String summary, List<RagChatPlanFileRef> files) {

    public RagChatPlanStep {
        if (files == null) {
            files = List.of();
        }
    }
}
