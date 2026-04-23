package com.bsg.docviz.dto;

import java.util.List;

/**
 * Resultado de la fase RAG (embeddings + chunks) antes de llamar al LLM; sirve para {@code call} o streaming.
 */
public record RagPreparedContext(
        String question,
        String userBlock,
        List<String> sources,
        String repoLabel
) {}
