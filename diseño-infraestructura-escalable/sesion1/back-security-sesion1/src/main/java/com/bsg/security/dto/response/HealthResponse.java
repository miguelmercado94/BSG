package com.bsg.security.dto.response;

import io.swagger.v3.oas.annotations.media.Schema;

/**
 * DTO de respuesta para el endpoint de salud.
 */
public record HealthResponse(
        @Schema(example = "UP")
        String status,
        @Schema(example = "back-security-sesion1")
        String application
) {
}
