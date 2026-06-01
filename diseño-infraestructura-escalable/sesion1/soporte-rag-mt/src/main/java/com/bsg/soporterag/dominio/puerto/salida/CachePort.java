package com.bsg.soporterag.dominio.puerto.salida;

import reactor.core.publisher.Mono;

import java.time.Duration;

public interface CachePort {

    Mono<String> obtener(String clave);

    Mono<Void> guardar(String clave, String valor, Duration ttl);

    Mono<Void> eliminar(String clave);

    boolean activa();
}
