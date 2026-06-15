package com.bsg.soporterag.aplicacion.servicio;

import com.bsg.soporterag.dominio.modelo.Repositorio;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

/**
 * Persistencia y consulta de {@link Repositorio} (solo modelo de dominio).
 */
public interface RepositorioServicio {

    Mono<Repositorio> crearNuevoRepo(Repositorio repositorio);

    Mono<Repositorio> actualizarRepo(Repositorio repositorio, String urlClaveOriginal);

    Mono<Void> eliminarRepo(String url);

    Mono<Repositorio> obtenerRepo(String url);

    Mono<Repositorio> obtenerRepoPorNombre(String nombre);

    Flux<Repositorio> obtenerTodosPorCelula(String codigoCelula);

    Flux<Repositorio> obtenerTodosPorTag(String nombreTag);

    Mono<Long> desasociarTagDeTodos(String nombreTag);
}
