package com.bsg.docviz.dto;

/**
 * Inicio del flujo indexación por archivo (pendiente sin célula).
 *
 * @param linkedWithoutReindex si es un enlace al índice canónico existente (no hay trabajo vectorial).
 */
public record PendingIndexBeginResponse(boolean linkedWithoutReindex, CellRepoResponse repo) {}
