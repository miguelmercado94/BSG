package com.bsg.soporterag.aplicacion.servicio;

import com.bsg.soporterag.dominio.modelo.AsociacionCelulaRepositorio;
import com.bsg.soporterag.dominio.modelo.Celula;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

/**
 * Operaciones de célula y sus asociaciones con repositorios.
 */
public interface CelulaServicio {

    // --- Operaciones sobre Células ---
    Flux<Celula> listarTodas();
    Mono<Celula> obtenerPorId(String id);
    Mono<Celula> obtenerPorCodigo(String codigo);
    Mono<Celula> crear(Celula celula);
    Mono<Celula> actualizar(String id, Celula celula);
    Mono<Void> eliminar(String id);

    // --- Operaciones sobre Asociaciones Célula-Repositorio ---
    Flux<String> listarNombresRepoPorCodigoCelula(String codigoCelula);
    Flux<Celula> listarCelulasPorNombreRepo(String nombreRepo);
    Mono<AsociacionCelulaRepositorio> asociarRepositorio(String codigoCelula, String nombreRepo);
    Mono<Void> desasociarRepositorio(String codigoCelula, String nombreRepo);
    Mono<Void> desasociarRepositorioDeTodasCelulas(String nombreRepo);
    Mono<Long> contarAsociacionesParaRepo(String nombreRepo);
    Mono<Boolean> existeAsociacion(String codigoCelula, String nombreRepo);
}
