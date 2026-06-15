package com.bsg.soporterag.aplicacion.servicio.impl;

import com.bsg.soporterag.aplicacion.dto.response.ResultadoAnalisisIntencionDto;
import com.bsg.soporterag.aplicacion.servicio.ChatServicio;
import com.bsg.soporterag.dominio.modelo.TipoTareaModelo;
import com.bsg.soporterag.dominio.puerto.salida.ProveedorChatPort;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Mono;

@Service
public class ChatServicioImpl implements ChatServicio {

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
            String jsonResponse = proveedorChatPort.chatearConContexto(
                    conversacionId,
                    mensaje,
                    toolsContexto,
                    TipoTareaModelo.ANALIZAR
            );
            
            try {
                String cleanedJson = jsonResponse.replaceAll("(?s).*?(\\{.*\\}).*", "$1");
                return objectMapper.readValue(cleanedJson, ResultadoAnalisisIntencionDto.class);
            } catch (Exception e) {
                return new ResultadoAnalisisIntencionDto(true, mensaje, true, true, null);
            }
        });
    }

    @Override
    public Mono<String> conversar(String conversacionId, String mensaje, String contextoExtraido) {
        return Mono.fromCallable(() -> proveedorChatPort.chatearConContexto(
                conversacionId,
                mensaje,
                contextoExtraido,
                TipoTareaModelo.RESPONDER
        ));
    }

    @Override
    public Mono<String> conversarDirecto(String conversacionId, String mensaje) {
        return Mono.fromCallable(() -> proveedorChatPort.chatearConContexto(
                conversacionId,
                mensaje,
                "", // Sin contexto RAG adicional
                TipoTareaModelo.RESPONDER
        ));
    }

    @Override
    public Mono<String> resumirConversacion(String conversacionId, String historialChat) {
        return Mono.fromCallable(() -> proveedorChatPort.chatearConContexto(
                conversacionId,
                "Genera un resumen conciso de la siguiente conversación:",
                historialChat,
                TipoTareaModelo.RESUMIR
        ));
    }
}
