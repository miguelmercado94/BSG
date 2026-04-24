package com.bsg.docviz.application.port.output;

import com.bsg.docviz.service.UserRepositoryState;

/**
 * Estado de sesión por usuario (repositorio Git conectado, caché, etc.).
 */
public interface SessionRegistryPort {

    UserRepositoryState current();

    UserRepositoryState getIfPresent(String userId);

    void remove(String userId);
}
