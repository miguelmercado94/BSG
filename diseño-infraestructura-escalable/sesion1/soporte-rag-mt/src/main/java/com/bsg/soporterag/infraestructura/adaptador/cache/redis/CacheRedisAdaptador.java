package com.bsg.soporterag.infraestructura.adaptador.cache.redis;

import com.bsg.soporterag.configuracion.CacheRedisPropiedades;
import com.bsg.soporterag.dominio.puerto.salida.CachePort;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.data.redis.core.ReactiveRedisTemplate;
import org.springframework.stereotype.Component;
import reactor.core.publisher.Mono;

import java.time.Duration;

@Component
@ConditionalOnProperty(prefix = "soporte-rag.cache.redis", name = "enabled", havingValue = "true")
public class CacheRedisAdaptador implements CachePort {

    private static final Logger log = LoggerFactory.getLogger(CacheRedisAdaptador.class);
    private static final Duration DEFAULT_TIMEOUT = Duration.ofMillis(500);

    private final ReactiveRedisTemplate<String, String> redis;
    private final CacheRedisPropiedades propiedades;

    public CacheRedisAdaptador(
            ReactiveRedisTemplate<String, String> redis,
            CacheRedisPropiedades propiedades) {
        this.redis = redis;
        this.propiedades = propiedades;
    }

    @Override
    public Mono<String> obtener(String clave) {
        return redis.opsForValue().get(prefijo(clave))
                .timeout(DEFAULT_TIMEOUT)
                .onErrorResume(e -> {
                    log.warn("Redis obtener clave={} fallo (continuando sin cache): {}", clave, e.getMessage());
                    return Mono.empty();
                });
    }

    @Override
    public Mono<Void> guardar(String clave, String valor, Duration ttl) {
        return redis.opsForValue()
                .set(prefijo(clave), valor, ttl)
                .timeout(DEFAULT_TIMEOUT)
                .then()
                .onErrorResume(e -> {
                    log.warn("Redis guardar clave={} fallo (continuando sin cache): {}", clave, e.getMessage());
                    return Mono.empty();
                });
    }

    @Override
    public Mono<Void> eliminar(String clave) {
        return redis.delete(prefijo(clave))
                .timeout(DEFAULT_TIMEOUT)
                .then()
                .onErrorResume(e -> {
                    log.warn("Redis eliminar clave={} fallo: {}", clave, e.getMessage());
                    return Mono.empty();
                });
    }

    @Override
    public boolean activa() {
        return true;
    }

    private String prefijo(String clave) {
        return propiedades.keyPrefix() + clave;
    }
}
