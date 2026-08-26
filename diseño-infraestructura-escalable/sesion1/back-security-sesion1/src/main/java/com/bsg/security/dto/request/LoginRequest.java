package com.bsg.security.dto.request;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;

/**
 * DTO de entrada para login (username o email + password; rol opcional).
 * Si {@code role} viene vacío, no se valida el nombre del rol contra el catálogo antes del login;
 * el rol y permisos efectivos se cargan desde la BD tras autenticar.
 */
public record LoginRequest(

    @NotBlank(message = "username o email es requerido")
    @Schema(example = "admin", description = "Username o email")
    String usernameOrEmail,

    @NotBlank(message = "password es requerido")
    @Schema(example = "password", description = "Password del usuario")
    String password,

    @Schema(example = "ROLE_ADMINISTRATOR", description = "Opcional. Si se envía, debe existir en BD antes de continuar.")
    String role
) {}
