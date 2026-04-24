package com.bsg.security.dto.request;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.Size;

/**
 * DTO de entrada para el registro de un usuario.
 * Contiene los datos del usuario (sin id ni active) y el nombre del rol (opcional, por defecto ROLE_ADMINISTRATOR).
 */
public record UserRegisterDto(

    @NotBlank(message = "username es requerido")
    @Schema(example = "juan.perez2")
    String username,

    @Email(message = "email debe ser válido")
    @NotBlank(message = "email es requerido")
    @Schema(example = "juan.perez2@ejemplo.com")
    String email,

    @Size(max = 20, message = "phone como máximo 20 caracteres")
    @Schema(example = "3003763311", description = "Opcional; si se omite se guarda como null")
    String phone,

    @NotBlank(message = "password es requerido")
    @Schema(example = "Password123*")
    String password,

    @Schema(example = "ROLE_ADMINISTRATOR", description = "Opcional; por defecto ROLE_ADMINISTRATOR")
    String roleName
) {}
