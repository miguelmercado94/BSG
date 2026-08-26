package com.bsg.soporterag.aplicacion.servicio;

import com.bsg.soporterag.aplicacion.dto.response.ResultadoAnalisisIntencionDto;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

/**
 * Servicio puro de interacción con la IA. No orquesta entidades de dominio (Tarea, Repo),
 * solo delega al puerto de IA procesando la entrada y salida.
 */
public interface ChatServicio {

    Mono<ResultadoAnalisisIntencionDto> analizar(String conversacionId, String mensaje, String herramientasDisponibles);

    Mono<String> conversar(String conversacionId, String mensaje, String contextoExtraido);

    Mono<String> conversarDirecto(String conversacionId, String mensaje);

    Mono<String> resumirConversacion(String conversacionId, String historialChat);

    /** Streaming token-por-token desde el LLM. */
    Flux<String> conversarStream(String conversacionId, String mensaje, String contextoExtraido);

    /** Streaming directo sin contexto RAG. */
    Flux<String> conversarDirectoStream(String conversacionId, String mensaje);
}
