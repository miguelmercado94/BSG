package com.bsg.docviz.dto;

/**
 * Propuesta para la UI tras restaurar desde S3 (borrador .txt o copia en workarea).
 */
public record RestoredWorkAreaProposalDto(
        String id,
        String fileName,
        String extension,
        String content,
        String draftRelativePath,
        String acceptedRelativePath) {}
