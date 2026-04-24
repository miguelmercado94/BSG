package com.bsg.docviz.vector;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.ai.embedding.EmbeddingModel;
import org.springframework.ai.embedding.EmbeddingResponse;

import java.util.ArrayList;
import java.util.List;

/**
 * Embeddings vía Spring AI (p. ej. Ollama con modelo nomic-embed-text).
 */
public class SpringAiEmbeddingClient implements EmbeddingClient {

    private static final Logger log = LoggerFactory.getLogger(SpringAiEmbeddingClient.class);

    private final EmbeddingModel embeddingModel;

    public SpringAiEmbeddingClient(EmbeddingModel embeddingModel) {
        this.embeddingModel = embeddingModel;
    }

    @Override
    public float[] embedQuery(String text) {
        try {
            EmbeddingResponse r = embeddingModel.embedForResponse(List.of(text));
            float[] out = r.getResults().get(0).getOutput();
            if (log.isDebugEnabled()) {
                log.debug("embedQuery: dimensión={}, modelo={}", out.length, embeddingModel.getClass().getSimpleName());
            }
            return out;
        } catch (RuntimeException e) {
            log.error(
                    "embedQuery falló ({}): {}",
                    embeddingModel.getClass().getName(),
                    e.getMessage() != null ? e.getMessage() : e.getClass().getSimpleName(),
                    e);
            throw e;
        }
    }

    @Override
    public List<float[]> embedTexts(List<String> texts) {
        if (texts == null || texts.isEmpty()) {
            return List.of();
        }
        int n = texts.size();
        try {
            EmbeddingResponse r = embeddingModel.embedForResponse(texts);
            List<float[]> out = new ArrayList<>(r.getResults().size());
            for (int i = 0; i < r.getResults().size(); i++) {
                out.add(r.getResults().get(i).getOutput());
            }
            if (out.size() != n) {
                log.error(
                        "embedTexts: respuesta inconsistente — pedidos {} textos, {} vectores (modelo={})",
                        n,
                        out.size(),
                        embeddingModel.getClass().getName());
            } else if (log.isDebugEnabled() && !out.isEmpty() && out.get(0) != null) {
                log.debug(
                        "embedTexts: {} vectores, dimensión primera={}, modelo={}",
                        out.size(),
                        out.get(0).length,
                        embeddingModel.getClass().getSimpleName());
            }
            return out;
        } catch (RuntimeException e) {
            log.error(
                    "embedTexts falló: {} textos, modelo={}, mensaje={}",
                    n,
                    embeddingModel.getClass().getName(),
                    e.getMessage() != null ? e.getMessage() : e.getClass().getSimpleName(),
                    e);
            throw e;
        }
    }
}
