package com.bsg.docviz.dto;

/**
 * Respuesta a GET .../delete-impact antes de borrar célula o repo (tareas que se eliminarán en cascada).
 */
public record DeleteImpactResponse(int taskCount) {}
