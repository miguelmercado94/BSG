package com.bsg.security.application.usecase.impl;

import com.bsg.security.application.port.output.persistence.RolOperationRepositoryPort;
import com.bsg.security.application.port.output.persistence.RolRepositoryPort;
import com.bsg.security.application.port.output.persistence.UserRolRepositoryPort;
import com.bsg.security.application.service.UsuarioService;
import com.bsg.security.application.usecase.CustomerManager;
import com.bsg.security.application.usecase.JwtManager;
import com.bsg.security.domain.model.Rol;
import com.bsg.security.domain.model.Usuario;
import com.bsg.security.dto.request.UserRegisterDto;
import com.bsg.security.dto.response.SaveUserResponse;
import com.bsg.security.exception.ResourceNotFoundException;
import com.bsg.security.util.ReactiveUserAuthoritiesLoader;
import com.bsg.security.util.UserOperationNames;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Mono;
/**
 * Implementación del caso de uso de registro de cliente.
 * Orquesta UsuarioService, RolRepositoryPort y PasswordEncoder.
 */
@Service
public class CustomerManagerImpl implements CustomerManager {

    private final UsuarioService usuarioService;
    private final RolRepositoryPort rolRepositoryPort;
    private final UserRolRepositoryPort userRolRepositoryPort;
    private final RolOperationRepositoryPort rolOperationRepositoryPort;
    private final PasswordEncoder passwordEncoder;
    private final JwtManager jwtManager;

    public CustomerManagerImpl(UsuarioService usuarioService,
                              RolRepositoryPort rolRepositoryPort,
                              UserRolRepositoryPort userRolRepositoryPort,
                              RolOperationRepositoryPort rolOperationRepositoryPort,
                              PasswordEncoder passwordEncoder,
                              JwtManager jwtManager) {
        this.usuarioService = usuarioService;
        this.rolRepositoryPort = rolRepositoryPort;
        this.userRolRepositoryPort = userRolRepositoryPort;
        this.rolOperationRepositoryPort = rolOperationRepositoryPort;
        this.passwordEncoder = passwordEncoder;
        this.jwtManager = jwtManager;
    }

    private static final String DEFAULT_REGISTER_ROLE = "ROLE_ADMINISTRATOR";

    @Override
    public Mono<SaveUserResponse> registerNewCustomer(UserRegisterDto request, String algorithm) {
        String phoneNorm = normalizePhone(request.phone());
        String roleEffective = (request.roleName() == null || request.roleName().isBlank())
                ? DEFAULT_REGISTER_ROLE
                : request.roleName().trim();
        Mono<Void> validation = validateUserNotExists(request.username(), request.email(), phoneNorm);
        Mono<SaveUserResponse> saveAndRespond = Mono.defer(() -> {
            Usuario usuario = new Usuario();
            usuario.setUsername(request.username());
            usuario.setEmail(request.email());
            usuario.setPhone(phoneNorm);
            usuario.setPassword(passwordEncoder.encode(request.password()));
            usuario.setActive(true);
            return usuarioService.save(usuario)
                    .flatMap(savedUser -> rolRepositoryPort.findByName(roleEffective)
                            .switchIfEmpty(Mono.error(new ResourceNotFoundException("Rol no encontrado: " + roleEffective)))
                            .flatMap(rol -> afterRoleAssigned(savedUser, rol, roleEffective, algorithm)));
        });
        return validation.then(saveAndRespond);
    }

    private static String normalizePhone(String phone) {
        if (phone == null || phone.isBlank()) {
            return null;
        }
        return phone.trim();
    }

    /**
     * Valida que no exista ya un usuario con el mismo username, email o teléfono.
     * Si alguno existe, devuelve Mono.error con mensaje claro.
     */
    private Mono<Void> validateUserNotExists(String username, String email, String phone) {
        Mono<Boolean> byUser = usuarioService.existsByUsername(username);
        Mono<Boolean> byEmail = usuarioService.existsByEmail(email);
        Mono<Boolean> byPhone = (phone == null || phone.isBlank())
                ? Mono.just(false)
                : usuarioService.existsByPhone(phone);
        return Mono.zip(byUser, byEmail, byPhone).flatMap(tuple -> {
            if (Boolean.TRUE.equals(tuple.getT1())) {
                return Mono.<Void>error(new IllegalArgumentException("El username ya está registrado"));
            }
            if (Boolean.TRUE.equals(tuple.getT2())) {
                return Mono.<Void>error(new IllegalArgumentException("El email ya está registrado"));
            }
            if (Boolean.TRUE.equals(tuple.getT3())) {
                return Mono.<Void>error(new IllegalArgumentException("El teléfono ya está registrado"));
            }
            return Mono.<Void>empty();
        });
    }

    private Mono<SaveUserResponse> afterRoleAssigned(Usuario savedUser, Rol rol, String roleName, String algorithm) {
        return userRolRepositoryPort.assignRoleToUser(savedUser.getId(), rol.getId())
                .then(Mono.fromCallable(() -> {
                    savedUser.setRol(rol);
                    return savedUser;
                }))
                .flatMap(userWithRol -> ReactiveUserAuthoritiesLoader.loadAuthoritiesFromDb(rolOperationRepositoryPort, userWithRol)
                        .flatMap(u -> jwtManager.buildTokensForUser(u, algorithm)
                                .map(tokens -> buildResponse(u, roleName, tokens.jwt(), tokens.jwtRefresh()))));
    }

    /** Misma convención que {@link com.bsg.security.presentation.controller.ProfileController}: nombres vía {@link UserOperationNames}. */
    private static SaveUserResponse buildResponse(Usuario user, String roleName, String jwt, String jwtRefresh) {
        return new SaveUserResponse(user.getUsername(), user.getEmail(),
                user.getPhone(), roleName, UserOperationNames.fromUsuario(user), jwt, jwtRefresh);
    }
}

