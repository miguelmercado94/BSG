package com.bsg.soporterag.aplicacion.casodeuso;

import com.bsg.soporterag.aplicacion.dto.request.ChatRequestDto;
import com.bsg.soporterag.aplicacion.dto.response.MensajeChatDto;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

public interface InteractuarChatCasoUso {

    Mono<MensajeChatDto> conversar(String codigoTarea, ChatRequestDto request);

    /**
     * Streaming SSE: emite tokens progresivamente. Al finalizar persiste el mensaje completo
     * y dispara el rolling summary si corresponde.
     */
    Flux<String> conversarStream(String codigoTarea, ChatRequestDto request);
}
