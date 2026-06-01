package com.bsg.soporterag.configuracion;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "soporte-rag.cache.redis")
public record CacheRedisPropiedades(
        boolean enabled,
        String keyPrefix
) {
}
