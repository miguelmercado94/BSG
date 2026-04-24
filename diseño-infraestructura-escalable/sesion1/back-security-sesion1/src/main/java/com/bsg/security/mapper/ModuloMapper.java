package com.bsg.security.mapper;

import com.bsg.security.domain.model.Modulo;
import com.bsg.security.infrastructure.entity.ModuleEntity;
import org.springframework.stereotype.Component;

/**
 * Mapeo Modulo ↔ {@link ModuleEntity}. Implementación manual para evitar fallos del APT MapStruct/Eclipse ({@code ArrayList} en cascada).
 */
@Component
public class ModuloMapper {

    public Modulo toDomain(ModuleEntity entity) {
        if (entity == null) {
            return null;
        }
        Modulo modulo = new Modulo();
        modulo.setId(entity.getId());
        modulo.setName(entity.getName());
        modulo.setPathBase(entity.getPathBase());
        modulo.setActive(entity.isActive());
        return modulo;
    }

    public ModuleEntity toEntity(Modulo domain) {
        if (domain == null) {
            return null;
        }
        ModuleEntity entity = new ModuleEntity();
        entity.setId(domain.getId());
        entity.setName(domain.getName());
        entity.setPathBase(domain.getPathBase());
        entity.setActive(domain.isActive());
        return entity;
    }
}
