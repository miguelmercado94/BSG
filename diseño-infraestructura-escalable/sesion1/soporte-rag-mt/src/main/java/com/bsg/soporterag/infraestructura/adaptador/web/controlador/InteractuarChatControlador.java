package com.bsg.soporterag.infraestructura.adaptador.web.controlador;

import com.bsg.soporterag.aplicacion.casodeuso.InteractuarChatCasoUso;
import com.bsg.soporterag.aplicacion.dto.request.ChatRequestDto;
import com.bsg.soporterag.aplicacion.dto.response.MensajeChatDto;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.web.bind.annotation.*;
import reactor.core.publisher.Mono;

@RestController
@RequestMapping("/api/v1/tareas/{codigoTarea}")
@Tag(name = "Chat RAG", description = "API para la interacción con el asistente de IA basado en RAG")
public class InteractuarChatControlador {

    private final InteractuarChatCasoUso interactuarChatCasoUso;

    public InteractuarChatControlador(InteractuarChatCasoUso interactuarChatCasoUso) {
        this.interactuarChatCasoUso = interactuarChatCasoUso;
    }

    @Operation(summary = "Enviar mensaje al chat", description = "Envía una consulta a la IA. La tarea debe estar en estado INICIADA. El sistema buscará contexto en la base de datos vectorial y devolverá la respuesta generada.")
    @PostMapping("/chat")
    public Mono<MensajeChatDto> conversar(
            @Parameter(description = "Código de la tarea que representa la conversación", required = true) @PathVariable String codigoTarea,
            @RequestBody ChatRequestDto request) {
        return interactuarChatCasoUso.conversar(codigoTarea, request);
    }
}
