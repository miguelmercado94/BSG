package com.bsg.soporterag.dominio.modelo;

/**
 * Fragmento indexado en pgvector.
 */
public record FragmentoVectorial(
        String id,
        String namespace,
        String fuente,
        int indiceFragmento,
        String contenido,
        float[] embedding
) {
}
