package com.bsg.soporterag.aplicacion.servicio;

import reactor.core.publisher.Mono;

import java.util.List;
import java.util.Map;

public interface ServicioEmbedding {

    Mono<Void> embedirArchivo(boolean esLocal, String urlRepo, String nombreArchivo, byte[] contenidoArchivo);

    Mono<Void> embedirArchivos(boolean esLocal, String urlRepo, Map<String, byte[]> archivos);

    Mono<Void> eliminarEmbedding(boolean esLocal, String urlRepo, String nombreArchivo);

    Mono<Void> actualizarEmbedding(boolean esLocal, String urlRepo, String nombreArchivo, byte[] contenidoArchivo);

    Mono<Void> eliminarEmbeddings(boolean esLocal, String urlRepo, List<String> nombresArchivos);

    Mono<Void> eliminarTodosEmbeddingsPorRepo(String urlRepo);
}
