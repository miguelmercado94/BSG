package com.bsg.security.mapper;

import com.bsg.security.domain.model.Operation;
import com.bsg.security.infrastructure.entity.OperationEntity;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.MappingConstants;
import org.mapstruct.NullValuePropertyMappingStrategy;

/**
 * Mapeo entre modelo de dominio Operation y entidad OperationEntity (MapStruct).
 * Los campos de auditoría solo existen en la entidad; se ignoran al mapear dominio → entidad.
 */
@Mapper(componentModel = MappingConstants.ComponentModel.SPRING,
        nullValuePropertyMappingStrategy = NullValuePropertyMappingStrategy.IGNORE)
public interface OperationMapper {

    @Mapping(target = "method", source = "httpMethod")
    Operation toDomain(OperationEntity entity);

    @Mapping(target = "createdAt", ignore = true)
    @Mapping(target = "updatedAt", ignore = true)
    @Mapping(target = "createdBy", ignore = true)
    @Mapping(target = "updatedBy", ignore = true)
    @Mapping(target = "httpMethod", source = "method")
    OperationEntity toEntity(Operation domain);
}
