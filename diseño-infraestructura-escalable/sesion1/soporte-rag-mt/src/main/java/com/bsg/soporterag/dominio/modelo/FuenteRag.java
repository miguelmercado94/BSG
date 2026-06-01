package com.bsg.soporterag.dominio.modelo;

/**
 * Fuentes RAG separadas: cada una persiste en su propia tabla pgvector.
 */
public enum FuenteRag {
    /** Código indexado desde repositorio Git ({@code repoLabel/ruta}). */
    GIT,
    /** Markdown/documentos de soporte en S3 ({@code soporte:clave}). */
    SOPORTE
}
