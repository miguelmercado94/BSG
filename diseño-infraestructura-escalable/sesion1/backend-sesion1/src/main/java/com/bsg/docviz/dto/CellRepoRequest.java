package com.bsg.docviz.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

/** Credencial en claro solo en alta/actualización; no devolver al cliente. */
public record CellRepoRequest(
        /** Opcional en alta: el servidor deriva el nombre desde la URL si viene vacío. */
        @Size(max = 200) String displayName,
        @NotBlank String repositoryUrl,
        @NotNull GitConnectionMode connectionMode,
        @Size(max = 500) String gitUsername,
        /** Token o contraseña HTTPS; opcional en PUT si no se rota. */
        String credentialPlain,
        @Size(max = 2000) String localPath,
        /** Etiquetas separadas por coma (p. ej. tags Git). */
        @Size(max = 2000) String tagsCsv,
        /**
         * Namespace vectorial compartido (p. ej. admin__mirepo) para que soporte vea los mismos .md indexados.
         * El administrador puede obtenerlo con GET /session/vector-namespace tras conectar.
         */
        @Size(max = 500) String vectorNamespace
) {}
