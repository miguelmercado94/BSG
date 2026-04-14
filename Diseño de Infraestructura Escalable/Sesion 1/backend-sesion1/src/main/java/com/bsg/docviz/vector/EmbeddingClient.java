package com.bsg.docviz.vector;

import java.util.List;

/**
 * Generación de embeddings (modelo remoto o Spring AI). Independiente del almacén vectorial.
 */
public interface EmbeddingClient {

    float[] embedQuery(String text);

    List<float[]> embedTexts(List<String> texts);
}
