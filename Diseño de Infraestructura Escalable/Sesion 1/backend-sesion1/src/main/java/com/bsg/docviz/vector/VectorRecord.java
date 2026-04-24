package com.bsg.docviz.vector;

/**
 * Un fragmento indexado: embedding + metadatos mostrados en RAG.
 */
public record VectorRecord(String id, float[] vector, String source, int chunkIndex, String userLabel) {
}
