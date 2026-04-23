package com.bsg.security.mapper;

import com.bsg.security.domain.model.Usuario;
import com.bsg.security.infrastructure.entity.UserEntity;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.MappingConstants;
import org.mapstruct.NullValuePropertyMappingStrategy;

/**
 * Mapeo entre modelo de dominio Usuario y entidad UserEntity (MapStruct).
 * Los campos de auditoría solo existen en la entidad; se ignoran al mapear dominio → entidad.
 */
@Mapper(componentModel = MappingConstants.ComponentModel.SPRING,
        nullValuePropertyMappingStrategy = NullValuePropertyMappingStrategy.IGNORE)
public interface UsuarioMapper {

    /** Rellenados fuera del mapper (joins / seguridad). Sin ignore, MapStruct APT puede fallar en cascada sobre tipos de colección. */
    @Mapping(target = "rol", ignore = true)
    @Mapping(target = "grantedAuthorities", ignore = true)
    @Mapping(target = "authorities", ignore = true)
    Usuario toDomain(UserEntity entity);

    @Mapping(target = "createdAt", ignore = true)
    @Mapping(target = "updatedAt", ignore = true)
    @Mapping(target = "createdBy", ignore = true)
    @Mapping(target = "updatedBy", ignore = true)
    UserEntity toEntity(Usuario domain);
}
