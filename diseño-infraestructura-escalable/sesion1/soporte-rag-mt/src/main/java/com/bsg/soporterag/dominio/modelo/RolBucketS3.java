package com.bsg.soporterag.dominio.modelo;

/**
 * Roles de bucket S3 (mismos nombres que backend-sesion1 / Terraform).
 */
public enum RolBucketS3 {
    /** Markdown y documentos de soporte para RAG. */
    SOPORTE,
    /** Borradores del área de trabajo ({@code userId/taskCode/…}). */
    BORRADORES,
    /** Archivos aceptados del área de trabajo. */
    WORKAREA
}
