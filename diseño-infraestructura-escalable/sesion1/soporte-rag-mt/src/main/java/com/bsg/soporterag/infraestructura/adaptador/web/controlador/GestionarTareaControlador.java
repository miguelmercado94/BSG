package com.bsg.soporterag.infraestructura.adaptador.web.controlador;

import com.bsg.soporterag.aplicacion.casodeuso.GestionarTareaCasoUso;
import com.bsg.soporterag.aplicacion.dto.request.ActualizarEstadoTareaRequestDto;
import com.bsg.soporterag.aplicacion.dto.request.ActualizarTareaRequestDto;
import com.bsg.soporterag.aplicacion.dto.request.CrearTareaRequestDto;
import com.bsg.soporterag.aplicacion.dto.response.TareaResponseDto;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

@RestController
@RequestMapping("/api/v1/tareas")
@Tag(name = "Tareas", description = "API para la gestión del ciclo de vida de las tareas RAG")
public class GestionarTareaControlador {

    private final GestionarTareaCasoUso gestionarTareaCasoUso;

    public GestionarTareaControlador(GestionarTareaCasoUso gestionarTareaCasoUso) {
        this.gestionarTareaCasoUso = gestionarTareaCasoUso;
    }

    @Operation(summary = "Crear nueva tarea", description = "Crea una tarea en estado BORRADOR validando que la célula y el repositorio existan y estén asociados.")
    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public Mono<TareaResponseDto> crearTarea(@RequestBody CrearTareaRequestDto request) {
        return gestionarTareaCasoUso.crearTarea(request);
    }

    @Operation(summary = "Actualizar tarea", description = "Actualiza el título, repositorio y enunciado de una tarea. Solo permitido si la tarea está en estado BORRADOR.")
    @PutMapping("/{codigoTarea}")
    public Mono<TareaResponseDto> actualizarTarea(
            @Parameter(description = "Código de la tarea", required = true) @PathVariable String codigoTarea,
            @RequestBody ActualizarTareaRequestDto request) {
        return gestionarTareaCasoUso.actualizarTarea(codigoTarea, request);
    }

    @Operation(summary = "Actualizar estado de tarea", description = "Cambia el estado de una tarea (BORRADOR, INICIADA, CANCELADA, TERMINADA) siguiendo las reglas de negocio. Al INICIAR, se sincroniza el repositorio automáticamente.")
    @PatchMapping("/{codigoTarea}/estado")
    public Mono<TareaResponseDto> actualizarEstado(
            @Parameter(description = "Código de la tarea", required = true) @PathVariable String codigoTarea,
            @RequestBody ActualizarEstadoTareaRequestDto request) {
        return gestionarTareaCasoUso.actualizarEstado(codigoTarea, request);
    }

    @Operation(summary = "Eliminar tarea", description = "Elimina permanentemente una tarea y su historial de chat asociado.")
    @DeleteMapping("/{codigoTarea}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public Mono<Void> eliminarTarea(
            @Parameter(description = "Código de la tarea a eliminar", required = true) @PathVariable String codigoTarea) {
        return gestionarTareaCasoUso.eliminarTarea(codigoTarea);
    }

    @Operation(summary = "Listar tareas por usuario", description = "Obtiene todas las tareas asociadas a un código de usuario específico.")
    @GetMapping("/usuario/{codigoUsuario}")
    public Flux<TareaResponseDto> obtenerTareasPorUsuario(
            @Parameter(description = "Código del usuario", required = true) @PathVariable String codigoUsuario) {
        return gestionarTareaCasoUso.obtenerTareasPorUsuario(codigoUsuario);
    }
}
