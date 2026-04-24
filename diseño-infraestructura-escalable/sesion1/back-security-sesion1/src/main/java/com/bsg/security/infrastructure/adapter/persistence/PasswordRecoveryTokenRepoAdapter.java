package com.bsg.security.infrastructure.adapter.persistence;

import com.bsg.security.application.port.output.persistence.PasswordRecoveryTokenRepositoryPort;
import com.bsg.security.domain.model.PasswordRecoveryToken;
import com.bsg.security.infrastructure.entity.PasswordRecoveryTokenEntity;
import com.bsg.security.infrastructure.repository.PasswordRecoveryTokenRepository;
import com.bsg.security.mapper.PasswordRecoveryTokenMapper;
import org.springframework.stereotype.Component;
import reactor.core.publisher.Mono;

import java.time.Instant;

/**
 * Adapter de persistencia para tokens de recuperación de contraseña.
 */
@Component
public class PasswordRecoveryTokenRepoAdapter implements PasswordRecoveryTokenRepositoryPort {

    private final PasswordRecoveryTokenRepository repository;
    private final PasswordRecoveryTokenMapper mapper;

    public PasswordRecoveryTokenRepoAdapter(PasswordRecoveryTokenRepository repository,
                                           PasswordRecoveryTokenMapper mapper) {
        this.repository = repository;
        this.mapper = mapper;
    }

    @Override
    public Mono<PasswordRecoveryToken> save(PasswordRecoveryToken token) {
        PasswordRecoveryTokenEntity entity = mapper.toEntity(token);
        return repository.save(entity)
                .map(mapper::toDomain);
    }

    @Override
    public Mono<PasswordRecoveryToken> findByToken(String token) {
        return repository.findByToken(token)
                .map(mapper::toDomain);
    }

    @Override
    public Mono<Void> markAsUsed(String token) {
        return repository.markAsUsedByToken(token)
                .then();
    }

    @Override
    public Mono<Void> deleteExpiredBefore(Instant before) {
        return repository.deleteByExpiresAtBefore(before)
                .then();
    }
}
