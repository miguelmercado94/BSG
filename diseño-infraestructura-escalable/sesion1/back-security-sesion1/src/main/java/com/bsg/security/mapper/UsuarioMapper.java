package com.bsg.security.mapper;

import com.bsg.security.domain.model.Usuario;
import com.bsg.security.infrastructure.entity.UserEntity;
import org.springframework.stereotype.Component;

/**
 * Mapeo usuario ↔ {@link UserEntity}. Implementación manual: {@link Usuario} implementa {@link org.springframework.security.core.userdetails.UserDetails};
 * MapStruct sobre ese tipo suele disparar APT en cascada (p. ej. colecciones / {@code ArrayList}) en Eclipse.
 */
@Component
public class UsuarioMapper {

    public Usuario toDomain(UserEntity entity) {
        if (entity == null) {
            return null;
        }
        Usuario usuario = new Usuario();
        usuario.setId(entity.getId());
        usuario.setUsername(entity.getUsername());
        usuario.setEmail(entity.getEmail());
        usuario.setPhone(entity.getPhone());
        usuario.setPassword(entity.getPassword());
        usuario.setActive(entity.isActive());
        return usuario;
    }

    public UserEntity toEntity(Usuario domain) {
        if (domain == null) {
            return null;
        }
        UserEntity userEntity = new UserEntity();
        userEntity.setId(domain.getId());
        userEntity.setPhone(domain.getPhone());
        userEntity.setUsername(domain.getUsername());
        userEntity.setPassword(domain.getPassword());
        userEntity.setEmail(domain.getEmail());
        userEntity.setActive(domain.isActive());
        return userEntity;
    }
}
