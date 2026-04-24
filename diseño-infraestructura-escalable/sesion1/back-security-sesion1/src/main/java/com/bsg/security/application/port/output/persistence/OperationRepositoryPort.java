package com.bsg.security.application.port.output.persistence;

import com.bsg.security.domain.model.Operation;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

/**
 * Puerto de salida para persistencia de Operation.
 */
public interface OperationRepositoryPort {

    Mono<Operation> findById(Long id);

    Mono<Operation> findByPathAndHttpMethod(String path, String httpMethod);

    /**
     * Operación del módulo identificado por {@code pathBase} (tabla {@code module.path_base}), ruta API relativa y verbo HTTP.
     * Resolución: primero coincidencia exacta de {@code path}; si no hay fila, coincidencia con plantillas en BD
     * (p. ej. petición {@code /admin/cells/3} ↔ fila {@code /admin/cells/{id}}).
     */
    Mono<Operation> findByModulePathBaseAndPathAndHttpMethod(String modulePathBase, String path, String httpMethod);

    Flux<Operation> findByModuleId(Long moduleId);

    Flux<Operation> findByActiveTrue();

    Mono<Operation> save(Operation operation);
}
