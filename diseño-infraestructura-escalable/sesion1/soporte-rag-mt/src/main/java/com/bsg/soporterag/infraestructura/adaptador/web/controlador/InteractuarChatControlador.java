package com.bsg.soporterag.infraestructura.adaptador.web.controlador;

import com.bsg.soporterag.aplicacion.casodeuso.InteractuarChatCasoUso;
import com.bsg.soporterag.aplicacion.dto.request.ChatRequestDto;
import com.bsg.soporterag.aplicacion.dto.response.MensajeChatDto;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.*;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

@RestController
@RequestMapping("/api/v1/tareas/{codigoTarea}")
@Tag(name = "Chat RAG", description = "API para la interacción con el asistente de IA basado en RAG")
public class InteractuarChatControlador {

    private final InteractuarChatCasoUso interactuarChatCasoUso;

    public InteractuarChatControlador(InteractuarChatCasoUso interactuarChatCasoUso) {
        this.interactuarChatCasoUso = interactuarChatCasoUso;
    }

    @Operation(summary = "Enviar mensaje al chat (respuesta completa)", description = "Envía una consulta a la IA y devuelve la respuesta completa. La tarea debe estar en estado INICIADA.")
    @PostMapping("/chat")
    public Mono<MensajeChatDto> conversar(
            @Parameter(description = "Código de la tarea", required = true) @PathVariable String codigoTarea,
            @RequestBody ChatRequestDto request) {
        return interactuarChatCasoUso.conversar(codigoTarea, request);
    }

    @Operation(summary = "Chat streaming (SSE)", description = "Envía una consulta y recibe la respuesta token por token via Server-Sent Events. Al completar el stream se persiste el mensaje y se procesa el rolling summary.")
    @PostMapping(value = "/chat/stream", produces = MediaType.TEXT_EVENT_STREAM_VALUE)
    public Flux<String> conversarStream(
            @Parameter(description = "Código de la tarea", required = true) @PathVariable String codigoTarea,
            @RequestBody ChatRequestDto request) {
        return interactuarChatCasoUso.conversarStream(codigoTarea, request);
    }
}
