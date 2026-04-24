package com.bsg.security.mapper;

import com.bsg.security.domain.model.Rol;
import com.bsg.security.infrastructure.entity.RoleEntity;
import org.springframework.stereotype.Component;

/**
 * Mapeo Rol ↔ {@link RoleEntity}. Implementación manual para evitar fallos del APT de MapStruct/Eclipse en este proyecto (errores en cascada sobre tipos como {@code ArrayList}).
 */
@Component
public class RolMapper {

    public Rol toDomain(RoleEntity entity) {
        if (entity == null) {
            return null;
        }
        Rol rol = new Rol();
        rol.setId(entity.getId());
        rol.setName(entity.getName());
        rol.setActive(entity.isActive());
        return rol;
    }

    public RoleEntity toEntity(Rol domain) {
        if (domain == null) {
            return null;
        }
        RoleEntity entity = new RoleEntity();
        entity.setId(domain.getId());
        entity.setName(domain.getName());
        entity.setActive(domain.isActive());
        return entity;
    }
}
