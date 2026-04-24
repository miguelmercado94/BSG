package com.bsg.security.mapper;

import com.bsg.security.domain.model.Operation;
import com.bsg.security.infrastructure.entity.OperationEntity;
import org.springframework.stereotype.Component;

/**
 * Mapeo Operation ↔ {@link OperationEntity}. Implementación manual (MapStruct/Eclipse APT puede fallar en cascada en este proyecto).
 * {@code method} en dominio ↔ {@code httpMethod} en entidad.
 */
@Component
public class OperationMapper {

    public Operation toDomain(OperationEntity entity) {
        if (entity == null) {
            return null;
        }
        Operation op = new Operation();
        op.setId(entity.getId());
        op.setName(entity.getName());
        op.setPath(entity.getPath());
        op.setMethod(entity.getHttpMethod());
        op.setModuleId(entity.getModuleId());
        op.setPermiteAll(entity.isPermiteAll());
        op.setActive(entity.isActive());
        return op;
    }

    public OperationEntity toEntity(Operation domain) {
        if (domain == null) {
            return null;
        }
        OperationEntity entity = new OperationEntity();
        entity.setId(domain.getId());
        entity.setPath(domain.getPath());
        entity.setName(domain.getName());
        entity.setHttpMethod(domain.getMethod());
        entity.setModuleId(domain.getModuleId());
        entity.setPermiteAll(domain.isPermiteAll());
        entity.setActive(domain.isActive());
        return entity;
    }
}
