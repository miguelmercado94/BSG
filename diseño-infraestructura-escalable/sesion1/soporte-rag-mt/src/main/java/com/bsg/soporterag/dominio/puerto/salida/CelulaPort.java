package com.bsg.soporterag.dominio.puerto.salida;

import com.bsg.soporterag.dominio.modelo.Celula;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

public interface CelulaPort {
    Flux<Celula> findAll();
    Mono<Celula> findById(String id);
    Mono<Celula> findByCodigo(String codigo);
    Mono<Celula> save(Celula celula);
    Mono<Void> deleteById(String id);
}