package com.bsg.soporterag.infraestructura.adaptador.web.controlador;

import com.bsg.soporterag.aplicacion.casodeuso.GestionarSoporteCasoUso;
import com.bsg.soporterag.aplicacion.dto.request.ActualizarSoporteRequestDto;
import com.bsg.soporterag.aplicacion.dto.request.CrearSoporteRequestDto;
import com.bsg.soporterag.aplicacion.dto.response.SoporteResponseDto;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

@RestController
@RequestMapping("/api/v1/soportes")
@Tag(name = "Documentos de Soporte", description = "API para la gestión de documentos de soporte (Markdown, etc.)")
public class GestionarSoporteControlador {

    private final GestionarSoporteCasoUso gestionarSoporteCasoUso;

    public GestionarSoporteControlador(GestionarSoporteCasoUso gestionarSoporteCasoUso) {
        this.gestionarSoporteCasoUso = gestionarSoporteCasoUso;
    }

    @Operation(summary = "Crear un nuevo documento de soporte", description = "Crea y embebe un nuevo documento de soporte asociado a un repositorio.")
    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public Mono<SoporteResponseDto> crearSoporte(@RequestBody CrearSoporteRequestDto request) {
        return gestionarSoporteCasoUso.crear(request);
    }

    @Operation(summary = "Actualizar un documento de soporte", description = "Actualiza los metadatos y/o el contenido (re-embedding) de un documento de soporte.")
    @PutMapping("/{codigo}")
    public Mono<SoporteResponseDto> actualizarSoporte(
            @Parameter(description = "Código del documento a actualizar", required = true) @PathVariable String codigo,
            @RequestBody ActualizarSoporteRequestDto request) {
        return gestionarSoporteCasoUso.actualizar(codigo, request);
    }

    @Operation(summary = "Eliminar un documento de soporte", description = "Elimina los metadatos y el embedding de un documento de soporte.")
    @DeleteMapping("/{codigo}")
    public Mono<SoporteResponseDto> eliminarSoporte(
            @Parameter(description = "Código del documento a eliminar", required = true) @PathVariable String codigo) {
        return gestionarSoporteCasoUso.eliminar(codigo);
    }

    @Operation(summary = "Obtener un documento de soporte por código", description = "Obtiene los detalles de un documento de soporte específico.")
    @GetMapping("/{codigo}")
    public Mono<SoporteResponseDto> obtenerSoportePorCodigo(
            @Parameter(description = "Código del documento a obtener", required = true) @PathVariable String codigo) {
        return gestionarSoporteCasoUso.obtenerPorCodigo(codigo);
    }

    @Operation(summary = "Obtener todos los documentos de soporte de un repositorio", description = "Lista todos los documentos de soporte asociados a una URL de repositorio.")
    @GetMapping
    public Flux<SoporteResponseDto> obtenerSoportesPorRepo(
            @Parameter(description = "URL del repositorio a consultar", required = true) @RequestParam String urlRepo) {
        return gestionarSoporteCasoUso.obtenerTodosPorUrlRepo(urlRepo);
    }
}
