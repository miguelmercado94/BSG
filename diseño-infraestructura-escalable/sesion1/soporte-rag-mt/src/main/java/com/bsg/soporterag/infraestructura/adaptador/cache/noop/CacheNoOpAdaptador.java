package com.bsg.soporterag.infraestructura.adaptador.cache.noop;

import com.bsg.soporterag.dominio.puerto.salida.CachePort;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;
import reactor.core.publisher.Mono;

import java.time.Duration;

@Component
@ConditionalOnProperty(prefix = "soporte-rag.cache.redis", name = "enabled", havingValue = "false", matchIfMissing = true)
public class CacheNoOpAdaptador implements CachePort {

    @Override
    public Mono<String> obtener(String clave) {
        return Mono.empty();
    }

    @Override
    public Mono<Void> guardar(String clave, String valor, Duration ttl) {
        return Mono.empty();
    }

    @Override
    public Mono<Void> eliminar(String clave) {
        return Mono.empty();
    }

    @Override
    public boolean activa() {
        return false;
    }
}
