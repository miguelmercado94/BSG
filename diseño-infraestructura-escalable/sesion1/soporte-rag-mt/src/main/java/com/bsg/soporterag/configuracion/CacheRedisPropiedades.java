package com.bsg.soporterag.configuracion;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "soporte-rag.cache.redis")
public record CacheRedisPropiedades(
        boolean enabled,
        String keyPrefix,
        /** Prefijo específico para las claves del historial de chat por HU (código de tarea). */
        String historialKeyPrefix,
        /** TTL en segundos del historial de chat cacheado. Si es <= 0 se usa 86400 (1 día). */
        long historialTtlSeconds
) {
    public String historialKeyPrefixOrDefault() {
        return (historialKeyPrefix == null || historialKeyPrefix.isBlank())
                ? "historial-chat:"
                : historialKeyPrefix;
    }

    public long historialTtlSecondsOrDefault() {
        return historialTtlSeconds > 0 ? historialTtlSeconds : 86400L;
    }
}
