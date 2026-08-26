package com.bsg.security.application.port.output.persistence;

import com.bsg.security.domain.model.Operation;
import reactor.core.publisher.Flux;

/**
 * Puerto para obtener las operaciones asignadas a un rol (tabla rol_operation).
 */
public interface RolOperationRepositoryPort {

    /**
     * Operaciones asociadas al rol. Si la tabla rol_operation está vacía para ese rol, devuelve Flux vacío.
     */
    Flux<Operation> findOperationsByRoleId(Integer roleId);
}
