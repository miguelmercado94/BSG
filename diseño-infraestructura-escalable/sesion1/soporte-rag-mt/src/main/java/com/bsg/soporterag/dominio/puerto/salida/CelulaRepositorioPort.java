package com.bsg.soporterag.dominio.puerto.salida;

import com.bsg.soporterag.dominio.modelo.AsociacionCelulaRepositorio;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

/**
 * Consulta la colección de unión {@code celula_repositorio} (N:M célula ↔ repo).
 */
public interface CelulaRepositorioPort {

    /**
     * {@code nombre_repo} asociados a una célula (clave para resolver el repo global).
     */
    Flux<String> listarNombresRepoPorCodigoCelula(String codigoCelula);

    /**
     * {@code codigo_celula} asociados a un repositorio.
     */
    Flux<String> listarCodigosCelulaPorNombreRepo(String nombreRepo);

    Mono<AsociacionCelulaRepositorio> guardarAsociacion(AsociacionCelulaRepositorio asociacion);

    Mono<Void> eliminarAsociacion(String codigoCelula, String nombreRepo);

    Mono<Void> eliminarTodasAsociacionesPorRepo(String nombreRepo);

    Mono<Long> contarAsociacionesPorRepo(String nombreRepo);
}
