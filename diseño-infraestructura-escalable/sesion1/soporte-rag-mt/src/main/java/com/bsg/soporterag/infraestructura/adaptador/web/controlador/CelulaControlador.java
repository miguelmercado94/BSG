package com.bsg.soporterag.infraestructura.adaptador.web.controlador;

import com.bsg.soporterag.aplicacion.casodeuso.GestionarCelulaCasoUso;
import com.bsg.soporterag.aplicacion.casodeuso.GestionarRepositorioCasoUso;
import com.bsg.soporterag.aplicacion.dto.request.CelulaRequestDto;
import com.bsg.soporterag.aplicacion.dto.response.CelulaResponseDto;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

@RestController
@RequestMapping("/api/v1/celulas")
@Tag(name = "Células", description = "API para la gestión de células y sus repositorios asociados")
public class CelulaControlador {

    private final GestionarCelulaCasoUso gestionarCelulaCasoUso;
    private final GestionarRepositorioCasoUso gestionarRepositorioCasoUso;

    public CelulaControlador(GestionarCelulaCasoUso gestionarCelulaCasoUso, GestionarRepositorioCasoUso gestionarRepositorioCasoUso) {
        this.gestionarCelulaCasoUso = gestionarCelulaCasoUso;
        this.gestionarRepositorioCasoUso = gestionarRepositorioCasoUso;
    }

    @Operation(summary = "Listar todas las células", description = "Obtiene un listado de todas las células registradas junto con sus repositorios")
    @ApiResponse(responseCode = "200", description = "Listado obtenido correctamente")
    @GetMapping
    public Flux<CelulaResponseDto> listarTodas() {
        return gestionarCelulaCasoUso.listarTodas();
    }

    @Operation(summary = "Obtener célula por código", description = "Obtiene los detalles de una célula específica a partir de su código")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Célula encontrada", content = @Content(schema = @Schema(implementation = CelulaResponseDto.class))),
            @ApiResponse(responseCode = "404", description = "Célula no encontrada", content = @Content)
    })
    @GetMapping("/{codigo}")
    public Mono<CelulaResponseDto> obtenerPorCodigo(
            @Parameter(description = "Código único de la célula", required = true)
            @PathVariable("codigo") String codigo) {
        return gestionarCelulaCasoUso.obtenerPorCodigo(codigo);
    }

    @Operation(summary = "Crear nueva célula", description = "Registra una nueva célula en el sistema")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "201", description = "Célula creada exitosamente", content = @Content(schema = @Schema(implementation = CelulaResponseDto.class))),
            @ApiResponse(responseCode = "400", description = "Datos de entrada inválidos", content = @Content)
    })
    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public Mono<CelulaResponseDto> crearCelula(
            @Parameter(description = "Datos de la célula a crear", required = true)
            @RequestBody CelulaRequestDto request) {
        return gestionarCelulaCasoUso.crear(request);
    }

    @Operation(summary = "Actualizar célula", description = "Actualiza los datos (nombre, descripción) de una célula existente")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Célula actualizada correctamente", content = @Content(schema = @Schema(implementation = CelulaResponseDto.class))),
            @ApiResponse(responseCode = "404", description = "Célula no encontrada", content = @Content)
    })
    @PutMapping("/{codigo}")
    public Mono<CelulaResponseDto> actualizarCelula(
            @Parameter(description = "Código de la célula a actualizar", required = true)
            @PathVariable("codigo") String codigo,
            @Parameter(description = "Nuevos datos para la célula", required = true)
            @RequestBody CelulaRequestDto request) {
        return gestionarCelulaCasoUso.actualizar(codigo, request);
    }

    @Operation(summary = "Eliminar célula", description = "Elimina una célula del sistema de forma permanente")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "204", description = "Célula eliminada correctamente"),
            @ApiResponse(responseCode = "404", description = "Célula no encontrada", content = @Content)
    })
    @DeleteMapping("/{codigo}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public Mono<Void> eliminarCelula(
            @Parameter(description = "Código de la célula a eliminar", required = true)
            @PathVariable("codigo") String codigo) {
        return gestionarCelulaCasoUso.eliminar(codigo);
    }

    @Operation(
            summary = "Desasociar repositorio de célula (Eliminación Base)",
            description = "Rompe el vínculo entre una célula y un repositorio. Si el repositorio queda sin ninguna célula asociada tras esta operación, se desencadena una eliminación completa del mismo (borrado en BD, Vectores y S3)."
    )
    @ApiResponses(value = {
            @ApiResponse(responseCode = "204", description = "Asociación eliminada correctamente"),
            @ApiResponse(responseCode = "404", description = "Célula o Repositorio no encontrado", content = @Content)
    })
    @DeleteMapping("/{codigoCelula}/repositorios")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public Mono<Void> desasociarRepositorio(
            @Parameter(description = "Código de la célula", required = true)
            @PathVariable("codigoCelula") String codigoCelula,
            @Parameter(description = "URL del repositorio a desvincular", required = true)
            @RequestParam("urlRepo") String urlRepo) {
        return gestionarRepositorioCasoUso.desasociarRepositorioDeCelula(urlRepo, codigoCelula);
    }
}
