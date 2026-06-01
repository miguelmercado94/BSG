package com.bsg.soporterag.dominio.modelo;

import java.util.List;

/**
 * Rutas relativas del árbol Git en una rama concreta.
 */
public record RutasRepositorioGit(
        List<String> filesPath,
        List<String> folderPath
) {
}
