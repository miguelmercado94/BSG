package com.bsg.docviz.vector;

/**
 * Resultado de búsqueda por similitud (antes Pinecone match).
 */
public record VectorMatch(String source, int chunkIndex, double score) {
}
