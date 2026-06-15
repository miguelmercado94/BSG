package com.bsg.soporterag.infraestructura.adaptador.web.controlador;

import com.bsg.soporterag.aplicacion.casodeuso.GestionarTagCasoUso;
import com.bsg.soporterag.aplicacion.dto.request.ActualizarTagRequestDto;
import com.bsg.soporterag.aplicacion.dto.request.CrearTagRequestDto;
import com.bsg.soporterag.aplicacion.dto.response.ActualizarTagResponseDto;
import com.bsg.soporterag.aplicacion.dto.response.TagResponseDto;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

@RestController
@RequestMapping("/api/v1/tags")
@Tag(name = "Tags", description = "API para la gestión de etiquetas globales y sus herramientas")
public class GestionarTagControlador {

    private final GestionarTagCasoUso gestionarTagCasoUso;

    public GestionarTagControlador(GestionarTagCasoUso gestionarTagCasoUso) {
        this.gestionarTagCasoUso = gestionarTagCasoUso;
    }

    @Operation(summary = "Crear un nuevo tag", description = "Registra un nuevo tag global que podrá ser asignado a repositorios.")
    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public Mono<TagResponseDto> crearTag(@RequestBody CrearTagRequestDto request) {
        return gestionarTagCasoUso.crearTag(request);
    }

    @Operation(summary = "Actualizar un tag", description = "Modifica los metadatos de un tag existente.")
    @PutMapping("/{nombreTag}")
    public Mono<ActualizarTagResponseDto> actualizarTag(
            @Parameter(description = "Nombre único del tag", required = true) @PathVariable String nombreTag,
            @RequestBody ActualizarTagRequestDto request) {
        return gestionarTagCasoUso.actualizarTag(nombreTag, request);
    }

    @Operation(summary = "Eliminar un tag", description = "Elimina un tag de la base de datos y lo desvincula de todos los repositorios que lo tengan asociado.")
    @DeleteMapping("/{nombreTag}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public Mono<Void> eliminarTag(
            @Parameter(description = "Nombre único del tag a eliminar", required = true) @PathVariable String nombreTag) {
        return gestionarTagCasoUso.eliminarTag(nombreTag);
    }

    @Operation(summary = "Obtener todos los tags", description = "Lista todos los tags globales registrados en el sistema.")
    @GetMapping
    public Flux<TagResponseDto> obtenerTodosTags() {
        return gestionarTagCasoUso.obtenerTodosTags();
    }

    @Operation(summary = "Obtener tag por nombre", description = "Devuelve los detalles de un tag específico, incluyendo sus herramientas URL.")
    @GetMapping("/{nombreTag}")
    public Mono<TagResponseDto> obtenerTagPorNombre(
            @Parameter(description = "Nombre único del tag", required = true) @PathVariable String nombreTag) {
        return gestionarTagCasoUso.obtenerTagPorNombre(nombreTag);
    }

    @Operation(summary = "Añadir herramienta a un tag", description = "Agrega una nueva URL a la lista de herramientas asociadas a este tag.")
    @PostMapping("/{nombreTag}/tools")
    @ResponseStatus(HttpStatus.CREATED)
    public Mono<Void> agregarUrlTool(
            @Parameter(description = "Nombre único del tag", required = true) @PathVariable String nombreTag,
            @Parameter(description = "URL de la herramienta", required = true) @RequestParam String urlTool,
            @Parameter(description = "Contexto o descripción de uso de la URL", required = true) @RequestParam String contextoUrl) {
        return gestionarTagCasoUso.agregarUrlTool(nombreTag, urlTool, contextoUrl);
    }

    @Operation(summary = "Eliminar herramienta de un tag", description = "Elimina una URL específica de la lista de herramientas de un tag.")
    @DeleteMapping("/{nombreTag}/tools")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public Mono<Void> eliminarUrlTool(
            @Parameter(description = "Nombre único del tag", required = true) @PathVariable String nombreTag,
            @Parameter(description = "URL exacta de la herramienta a eliminar", required = true) @RequestParam String urlTool) {
        return gestionarTagCasoUso.eliminarUrlTool(nombreTag, urlTool);
    }
}
