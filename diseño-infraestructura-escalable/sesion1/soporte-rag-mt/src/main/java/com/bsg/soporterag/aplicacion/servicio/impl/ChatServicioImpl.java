package com.bsg.soporterag.aplicacion.servicio.impl;

import com.bsg.soporterag.aplicacion.dto.response.ResultadoAnalisisIntencionDto;
import com.bsg.soporterag.aplicacion.servicio.ChatServicio;
import com.bsg.soporterag.dominio.modelo.TipoTareaModelo;
import com.bsg.soporterag.dominio.puerto.salida.ProveedorChatPort;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

@Service
public class ChatServicioImpl implements ChatServicio {

    private static final Logger log = LoggerFactory.getLogger(ChatServicioImpl.class);

    private final ProveedorChatPort proveedorChatPort;
    private final ObjectMapper objectMapper;

    public ChatServicioImpl(
            ProveedorChatPort proveedorChatPort,
            ObjectMapper objectMapper) {
        this.proveedorChatPort = proveedorChatPort;
        this.objectMapper = objectMapper;
    }

    @Override
    public Mono<ResultadoAnalisisIntencionDto> analizar(String conversacionId, String mensaje, String herramientasDisponibles) {
        String toolsContexto = (herramientasDisponibles == null || herramientasDisponibles.isEmpty())
                ? "No hay herramientas disponibles."
                : herramientasDisponibles;

        return Mono.fromCallable(() -> {
            log.info("[ANALIZAR] Pregunta: '{}' | Herramientas: '{}'", mensaje, toolsContexto);
            String jsonResponse = proveedorChatPort.chatearConContexto(
                    conversacionId,
                    mensaje,
                    toolsContexto,
                    TipoTareaModelo.ANALIZAR
            );
            log.info("[ANALIZAR] Respuesta cruda de LLM: '{}'", jsonResponse);

            try {
                String cleanedJson = jsonResponse.replaceAll("(?s).*?(\\{.*\\}).*", "$1");
                ResultadoAnalisisIntencionDto dto = objectMapper.readValue(cleanedJson, ResultadoAnalisisIntencionDto.class);
                log.info("[ANALIZAR] Resultado parsed: {}", dto);
                return dto;
            } catch (Exception e) {
                log.error("[ANALIZAR] Error parseando respuesta JSON de LLM, usando fallback.", e);
                return new ResultadoAnalisisIntencionDto(true, mensaje, true, true, null);
            }
        });
    }

    @Override
    public Mono<String> conversar(String conversacionId, String mensaje, String contextoExtraido) {
        return Mono.fromCallable(() -> {
            log.info("[CHAT] conversacionId='{}' | Pregunta: '{}' | Contexto: '{}'", conversacionId, mensaje, contextoExtraido);
            String response = proveedorChatPort.chatearConContexto(
                    conversacionId,
                    mensaje,
                    contextoExtraido,
                    TipoTareaModelo.RESPONDER
            );
            log.info("[CHAT] Respuesta: '{}'", response);
            return response;
        });
    }

    @Override
    public Mono<String> conversarDirecto(String conversacionId, String mensaje) {
        return Mono.fromCallable(() -> {
            log.info("[CHAT-DIRECTO] conversacionId='{}' | Pregunta: '{}'", conversacionId, mensaje);
            String response = proveedorChatPort.chatearConContexto(
                    conversacionId,
                    mensaje,
                    "",
                    TipoTareaModelo.RESPONDER
            );
            log.info("[CHAT-DIRECTO] Respuesta: '{}'", response);
            return response;
        });
    }

    @Override
    public Flux<String> conversarStream(String conversacionId, String mensaje, String contextoExtraido) {
        log.info("[CHAT-STREAM] conversacionId='{}' | Pregunta: '{}' | Contexto: '{}'", conversacionId, mensaje, contextoExtraido);
        return proveedorChatPort.chatearConContextoStream(
                conversacionId,
                mensaje,
                contextoExtraido,
                TipoTareaModelo.RESPONDER
        );
    }

    @Override
    public Flux<String> conversarDirectoStream(String conversacionId, String mensaje) {
        log.info("[CHAT-DIRECTO-STREAM] conversacionId='{}' | Pregunta: '{}'", conversacionId, mensaje);
        return proveedorChatPort.chatearConContextoStream(
                conversacionId,
                mensaje,
                "",
                TipoTareaModelo.RESPONDER
        );
    }
}
