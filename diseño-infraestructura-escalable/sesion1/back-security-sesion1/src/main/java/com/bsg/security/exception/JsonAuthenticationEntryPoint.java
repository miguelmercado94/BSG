package com.bsg.security.exception;

import com.bsg.security.messages.ApiMessages;
import org.springframework.http.HttpStatus;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.web.server.ServerAuthenticationEntryPoint;
import org.springframework.stereotype.Component;
import org.springframework.web.server.ServerWebExchange;
import reactor.core.publisher.Mono;

import java.util.Locale;

@Component
public class JsonAuthenticationEntryPoint implements ServerAuthenticationEntryPoint {

    private final SecurityErrorResponseWriter errorResponseWriter;

    public JsonAuthenticationEntryPoint(SecurityErrorResponseWriter errorResponseWriter) {
        this.errorResponseWriter = errorResponseWriter;
    }

    @Override
    public Mono<Void> commence(ServerWebExchange exchange, AuthenticationException ex) {
        return errorResponseWriter.write(exchange, HttpStatus.UNAUTHORIZED, userFacingUnauthorizedMessage(ex));
    }

    /**
     * Spring Security suele enviar mensajes en inglés ("Not authenticated", "Bad credentials").
     * Los normalizamos para que la SPA muestre texto coherente con el resto de la API.
     */
    static String userFacingUnauthorizedMessage(AuthenticationException ex) {
        if (ex instanceof BadCredentialsException) {
            return "Usuario o contraseña incorrectos.";
        }
        if (ex == null || ex.getMessage() == null || ex.getMessage().isBlank()) {
            return ApiMessages.Security.UNAUTHENTICATED_OR_INVALID_TOKEN;
        }
        String raw = ex.getMessage().trim();
        String lower = raw.toLowerCase(Locale.ROOT);
        if (lower.contains("bad credentials")) {
            return "Usuario o contraseña incorrectos.";
        }
        if (lower.contains("not authenticated")
                || lower.contains("full authentication is required")
                || lower.contains("authentication object was not found")) {
            return ApiMessages.Security.UNAUTHENTICATED_OR_INVALID_TOKEN;
        }
        return raw;
    }
}

