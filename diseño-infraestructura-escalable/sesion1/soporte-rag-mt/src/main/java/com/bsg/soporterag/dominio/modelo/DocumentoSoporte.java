package com.bsg.soporterag.dominio.modelo;

import java.time.Instant;

/**
 * Metadatos de un documento de soporte.
 * <p>
 * El binario reside bajo {@code urlBucketS3}, normalmente dentro del prefijo
 * {@code urlFolderS3Workarea} del {@link #nombreRepo()} asociado (bucket {@link RolBucketS3#WORKAREA}).
 * El índice semántico vive en pgvector ({@code namespaceVectorial}).
 */
public record DocumentoSoporte(
        String id,
        String codigoSoporte,
        String nombreRepo,
        String nombre,
        String descripcion,
        String namespaceVectorial,
        String urlBucketS3,
        RolBucketS3 bucketRol,
        boolean indexado,
        Instant actualizadoEn
) {
}
