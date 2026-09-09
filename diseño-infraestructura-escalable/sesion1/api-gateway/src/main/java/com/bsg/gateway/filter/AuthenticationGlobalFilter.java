package com.bsg.gateway.filter;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.cloud.gateway.filter.GatewayFilterChain;
import org.springframework.cloud.gateway.filter.GlobalFilter;
import org.springframework.core.Ordered;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.server.reactive.ServerHttpRequest;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.client.WebClient;
import org.springframework.web.server.ServerWebExchange;
import reactor.core.publisher.Mono;

/**
 * Filtro global del API Gateway que valida autenticacion contra back-security.
 * <p>
 * Flujo:
 * 1. Rutas hacia /security-auth/** pasan directo (el micro de auth se protege solo).
 * 2. Rutas publicas del core (health, actuator) pasan directo.
 * 3. Para el resto (/docviz/**): extrae el JWT del header Authorization,
 *    llama a back-security /api/v1/auth/validate para verificar validez y permisos.
 * 4. Si el token es invalido o ausente -> 401.
 */
@Component
public class AuthenticationGlobalFilter implements GlobalFilter, Ordered {

    private static final Logger log = LoggerFactory.getLogger(AuthenticationGlobalFilter.class);

    private final WebClient securityClient;

    public AuthenticationGlobalFilter(
            @Value("${bsg.gateway.security-service-uri:http://localhost:8081}") String securityUri) {
        this.securityClient = WebClient.builder()
                .baseUrl(securityUri)
                .build();
    }

    @Override
    public int getOrder() {
        return -1; // Alta prioridad: ejecutar antes de otros filtros
    }

    @Override
    public Mono<Void> filter(ServerWebExchange exchange, GatewayFilterChain chain) {
        ServerHttpRequest request = exchange.getRequest();
        String path = request.getPath().pathWithinApplication().value();

        // 1. Rutas de auth pasan directo (el micro security se protege internamente)
        if (path.startsWith("/security-auth") || path.startsWith("/api/auth")) {
            return chain.filter(exchange);
        }

        // 2. Rutas publicas del core
        if (isPublicPath(path)) {
            return chain.filter(exchange);
        }

        // 3. Extraer JWT: header Authorization o, en handshakes WebSocket, query param ?token=
        //    (el navegador no permite cabeceras custom en new WebSocket(...), así que el token viaja en la URL).
        String token = extraerToken(request, path);
        if (token == null || token.isBlank()) {
            log.debug("Sin token JWT para path={}", path);
            return unauthorized(exchange);
        }

        // 4. Llamar a back-security para validar el token
        return securityClient.get()
                .uri("/security-auth/api/v1/auth/validate")
                .header(HttpHeaders.AUTHORIZATION, "Bearer " + token)
                .retrieve()
                .bodyToMono(ValidateResponse.class)
                .flatMap(response -> {
                    if (response == null || !response.tokenValid()) {
                        log.debug("Token invalido para path={}", path);
                        return unauthorized(exchange);
                    }
                    log.trace("Token valido para path={}, user={}", path, response.payload() != null ? response.payload().sub() : "unknown");
                    // Propagar info del usuario al downstream
                    ServerHttpRequest mutatedRequest = request.mutate()
                            .header("X-User-Id", response.payload() != null && response.payload().sub() != null ? response.payload().sub() : "")
                            .header("X-User-Authorities", response.payload() != null && response.payload().authorities() != null ? String.join(",", response.payload().authorities()) : "")
                            .build();
                    return chain.filter(exchange.mutate().request(mutatedRequest).build());
                })
                .onErrorResume(ex -> {
                    log.error("Error validando token contra back-security: {}", ex.getMessage());
                    return unauthorized(exchange);
                });
    }

    /**
     * Obtiene el JWT. Prioriza el header Authorization: Bearer. Para handshakes WebSocket
     * (rutas /ws/ con Upgrade: websocket) acepta también el query param ?token=, porque el
     * navegador no puede enviar cabeceras custom al abrir un WebSocket.
     */
    private String extraerToken(ServerHttpRequest request, String path) {
        String authHeader = request.getHeaders().getFirst(HttpHeaders.AUTHORIZATION);
        if (authHeader != null && authHeader.startsWith("Bearer ")) {
            return authHeader.substring(7);
        }
        if (esHandshakeWebSocket(request, path)) {
            return request.getQueryParams().getFirst("token");
        }
        return null;
    }

    private boolean esHandshakeWebSocket(ServerHttpRequest request, String path) {
        if (!path.contains("/ws/")) {
            return false;
        }
        String upgrade = request.getHeaders().getUpgrade();
        return upgrade != null && "websocket".equalsIgnoreCase(upgrade);
    }

    private boolean isPublicPath(String path) {
        return path.equals("/docviz/api/v1/infraestructura/salud")
                || path.startsWith("/docviz/actuator");
    }

    private Mono<Void> unauthorized(ServerWebExchange exchange) {
        exchange.getResponse().setStatusCode(HttpStatus.UNAUTHORIZED);
        return exchange.getResponse().setComplete();
    }

    /**
     * DTO para la respuesta de /api/v1/auth/validate del back-security.
     */
    record ValidateResponse(boolean tokenValid, Object header, TokenPayload payload) {}
    record TokenPayload(String sub, String[] authorities) {}
}
