package com.bsg.soporterag.aplicacion.servicio;

import reactor.core.publisher.Mono;

import java.util.List;
import java.util.Map;

public interface ServicioEmbedding {

    Mono<Void> embedirArchivo(boolean esLocal, String nombreRepo, String nombreArchivo, byte[] contenidoArchivo);

    Mono<Void> embedirArchivos(boolean esLocal, String nombreRepo, Map<String, byte[]> archivos);

    Mono<Void> eliminarEmbedding(boolean esLocal, String nombreRepo, String nombreArchivo);

    Mono<Void> actualizarEmbedding(boolean esLocal, String nombreRepo, String nombreArchivo, byte[] contenidoArchivo);

    Mono<Void> eliminarEmbeddings(boolean esLocal, String nombreRepo, List<String> nombresArchivos);

    Mono<Void> eliminarTodosEmbeddingsPorRepo(String nombreRepo);
}