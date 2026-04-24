package com.bsg.security.infrastructure.adapter.persistence;

import com.bsg.security.application.port.output.persistence.RolOperationRepositoryPort;
import com.bsg.security.domain.model.Operation;
import com.bsg.security.infrastructure.repository.RolOperationRepository;
import com.bsg.security.infrastructure.repository.OperationRepository;
import com.bsg.security.mapper.OperationMapper;
import org.springframework.stereotype.Component;
import reactor.core.publisher.Flux;

/**
 * Adapter que implementa RolOperationRepositoryPort: obtiene las operaciones de un rol
 * desde rol_operation y la tabla operation.
 */
@Component
public class RolOperationRepoAdapter implements RolOperationRepositoryPort {

    private final RolOperationRepository rolOperationRepository;
    private final OperationRepository operationRepository;
    private final OperationMapper operationMapper;

    public RolOperationRepoAdapter(RolOperationRepository rolOperationRepository,
                                   OperationRepository operationRepository,
                                   OperationMapper operationMapper) {
        this.rolOperationRepository = rolOperationRepository;
        this.operationRepository = operationRepository;
        this.operationMapper = operationMapper;
    }

    @Override
    public Flux<Operation> findOperationsByRoleId(Integer roleId) {
        return rolOperationRepository.findByRoleId(roleId)
                .flatMap(ro -> operationRepository.findById(ro.getOperationId())
                        .map(operationMapper::toDomain));
    }
}
