package com.bsg.security.application.port.output.persistence;

import com.bsg.security.domain.model.PasswordRecoveryToken;
import reactor.core.publisher.Mono;

/**
 * Puerto de salida para persistencia de tokens de recuperación de contraseña.
 */
public interface PasswordRecoveryTokenRepositoryPort {

    Mono<PasswordRecoveryToken> save(PasswordRecoveryToken token);

    Mono<PasswordRecoveryToken> findByToken(String token);

    Mono<Void> markAsUsed(String token);

    Mono<Void> deleteExpiredBefore(java.time.Instant before);
}
