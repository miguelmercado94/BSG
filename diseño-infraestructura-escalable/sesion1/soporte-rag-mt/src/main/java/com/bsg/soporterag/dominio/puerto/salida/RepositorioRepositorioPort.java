package com.bsg.soporterag.dominio.puerto.salida;

import com.bsg.soporterag.dominio.modelo.Repositorio;
import reactor.core.publisher.Mono;

/**
 * Puerto de persistencia del agregado {@link Repositorio}.
 */
public interface RepositorioRepositorioPort {

    Mono<Repositorio> guardar(Repositorio repositorio);

    Mono<Repositorio> buscarPorUrl(String url);

    Mono<Repositorio> buscarPorNombre(String nombreRepo);

    Mono<Boolean> existePorUrl(String url);

    Mono<Void> eliminar(Repositorio repositorio);
}
