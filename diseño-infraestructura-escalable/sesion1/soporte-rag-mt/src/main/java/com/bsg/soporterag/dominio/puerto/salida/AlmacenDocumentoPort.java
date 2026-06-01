package com.bsg.soporterag.dominio.puerto.salida;

import com.bsg.soporterag.dominio.modelo.DocumentoSoporte;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

public interface AlmacenDocumentoPort {

    Mono<DocumentoSoporte> guardar(DocumentoSoporte documento);

    Mono<DocumentoSoporte> buscarPorId(String id);

    Mono<DocumentoSoporte> buscarPorCodigo(String codigoSoporte);

    Flux<DocumentoSoporte> listarPorNombreRepo(String nombreRepo);
    
    Mono<Void> eliminarPorCodigo(String codigoSoporte);
}
