package com.bsg.soporterag.dominio.modelo;

import java.util.List;

/**
 * Metadatos Git obtenidos del remoto al registrar o refrescar un repositorio.
 */
public record InventarioRepositorioGit(
        String ramaPrincipal,
        String ultimoCommit,
        List<String> filesPath,
        List<String> folderPath
) {
}
