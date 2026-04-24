package com.bsg.docviz.vector;

import java.util.List;

/**
 * Persistencia y búsqueda de vectores (PostgreSQL/pgvector, Pinecone u otro).
 */
public interface VectorStore {

    void upsertBatch(String namespace, List<VectorRecord> records);

    List<VectorMatch> queryTopK(String namespace, float[] vector, int topK, String userLabel);

    void deleteAllInNamespace(String namespace);

    /** Borra todos los vectores cuyo campo metadata/source coincide (p. ej. un documento de soporte). */
    void deleteBySource(String namespace, String source);
}
