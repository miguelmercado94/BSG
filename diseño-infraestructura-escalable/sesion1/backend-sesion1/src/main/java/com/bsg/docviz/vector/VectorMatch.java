package com.bsg.docviz.vector;

/**
 * Resultado de búsqueda por similitud vectorial.
 */
public record VectorMatch(String source, int chunkIndex, double score) {
}
