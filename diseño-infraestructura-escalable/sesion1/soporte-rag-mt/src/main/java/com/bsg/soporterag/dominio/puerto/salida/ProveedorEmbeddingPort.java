package com.bsg.soporterag.dominio.puerto.salida;

import reactor.core.publisher.Mono;

import java.util.List;

public interface ProveedorEmbeddingPort {

    Mono<float[]> embedir(String texto);

    Mono<List<float[]>> embedirLote(List<String> textos);
}
