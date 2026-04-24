package com.bsg.docviz.application.port.output;

import com.bsg.docviz.dto.FileContentResponse;

/**
 * Lectura de archivos del repositorio conectado (vista / caché de sesión).
 */
public interface FileExplorerPort {

    FileContentResponse readFile(String queryPath);
}
