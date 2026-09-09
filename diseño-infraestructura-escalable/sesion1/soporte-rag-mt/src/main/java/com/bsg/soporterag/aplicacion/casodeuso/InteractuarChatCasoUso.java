package com.bsg.soporterag.aplicacion.casodeuso;

import com.bsg.soporterag.aplicacion.dto.request.ChatRequestDto;
import com.bsg.soporterag.aplicacion.dto.response.MensajeChatDto;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

public interface InteractuarChatCasoUso {

    Mono<MensajeChatDto> conversar(String codigoTarea, ChatRequestDto request);

    /**
     * Streaming SSE/WebSocket: emite tokens progresivamente. Al finalizar persiste el mensaje
     * completo y refresca la cache del historial.
     */
    Flux<String> conversarStream(String codigoTarea, ChatRequestDto request);

    /**
     * Historial de la conversación de una HU ya formateado como texto (últimos mensajes).
     * Usado al activar un canal WebSocket para pintar la conversación previa.
     */
    Mono<String> obtenerHistorialFormateado(String codigoTarea);
}
