package com.bsg.soporterag.aplicacion.servicio;

import com.bsg.soporterag.dominio.modelo.DocumentoSoporte;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

public interface DocumentoSoporteServicio {

    Mono<DocumentoSoporte> crear(DocumentoSoporte documento);

    Mono<DocumentoSoporte> actualizar(String codigoSoporte, DocumentoSoporte documento);

    Mono<DocumentoSoporte> obtenerPorCodigo(String codigoSoporte);

    Flux<DocumentoSoporte> obtenerTodosPorUrlRepo(String urlRepo);

    Mono<Void> eliminar(String codigoSoporte);
}
