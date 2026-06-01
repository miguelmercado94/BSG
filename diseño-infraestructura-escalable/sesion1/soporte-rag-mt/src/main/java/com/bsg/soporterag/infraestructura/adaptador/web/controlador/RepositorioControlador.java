package com.bsg.soporterag.infraestructura.adaptador.web.controlador;

import com.bsg.soporterag.aplicacion.casodeuso.GestionarRepositorioCasoUso;
import com.bsg.soporterag.aplicacion.dto.request.ActualizarRepositorioRequestDto;
import com.bsg.soporterag.aplicacion.dto.request.IndexarArchivoRequestDto;
import com.bsg.soporterag.aplicacion.dto.request.RepositorioRequestDto;
import com.bsg.soporterag.aplicacion.dto.response.IndexacionArchivoResponseDto;
import com.bsg.soporterag.aplicacion.dto.response.IndexacionCompletaResponseDto;
import com.bsg.soporterag.aplicacion.dto.response.RepositorioResponseDto;
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
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;
import reactor.core.publisher.Mono;

@RestController
@RequestMapping("/api/v1/repositorios")
@Tag(name = "Repositorios", description = "API para la gestión e indexación de repositorios Git (RAG)")
public class RepositorioControlador {

    private final GestionarRepositorioCasoUso gestionarRepositorioCasoUso;

    public RepositorioControlador(GestionarRepositorioCasoUso gestionarRepositorioCasoUso) {
        this.gestionarRepositorioCasoUso = gestionarRepositorioCasoUso;
    }

    @Operation(
            summary = "Crear e indexar repositorio",
            description = "Registra un nuevo repositorio Git, lo vincula a una célula, extrae su árbol de archivos, " +
                          "y prepara la infraestructura (S3) para su indexación. Inicia el proceso de RAG."
    )
    @ApiResponses(value = {
            @ApiResponse(responseCode = "201", description = "Repositorio creado e indexado correctamente",
                    content = @Content(schema = @Schema(implementation = RepositorioResponseDto.class))),
            @ApiResponse(responseCode = "400", description = "Datos de entrada inválidos o URL incorrecta", content = @Content)
    })
    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public Mono<RepositorioResponseDto> crearRepositorio(
            @Parameter(description = "Datos del repositorio a indexar", required = true)
            @RequestBody RepositorioRequestDto request) {
        return gestionarRepositorioCasoUso.crearRepo(request);
    }

    @Operation(
            summary = "Actualizar y sincronizar repositorio",
            description = "Actualiza los metadatos de un repositorio existente y sincroniza los embeddings " +
                          "(agrega, modifica o elimina) si se detectan nuevos commits en la rama especificada."
    )
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Repositorio actualizado y sincronizado",
                    content = @Content(schema = @Schema(implementation = RepositorioResponseDto.class))),
            @ApiResponse(responseCode = "404", description = "Repositorio no encontrado", content = @Content)
    })
    @PutMapping
    public Mono<RepositorioResponseDto> actualizarRepositorio(
            @Parameter(description = "Datos de actualización (URL es obligatoria como identificador)", required = true)
            @RequestBody ActualizarRepositorioRequestDto request) {
        return gestionarRepositorioCasoUso.actualizarRepo(request);
    }

    @Operation(
            summary = "Eliminación forzosa completa de repositorio",
            description = "Elimina un repositorio del sistema completamente: borra todos sus metadatos, " +
                          "limpia todos los embeddings asociados en la base de datos vectorial, elimina su carpeta " +
                          "en S3 y rompe TODAS las asociaciones que tuviera con cualquier célula."
    )
    @ApiResponses(value = {
            @ApiResponse(responseCode = "204", description = "Repositorio y todos sus datos asociados eliminados correctamente"),
            @ApiResponse(responseCode = "404", description = "Repositorio no encontrado", content = @Content)
    })
    @DeleteMapping
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public Mono<Void> eliminarRepositorioCompleto(
            @Parameter(description = "URL del repositorio a eliminar", required = true, example = "https://github.com/mi-org/mi-repo.git")
            @RequestParam("url") String urlRepo) {
        return gestionarRepositorioCasoUso.eliminarRepo(urlRepo);
    }

    @Operation(
            summary = "Obtener detalles enriquecidos de repositorio",
            description = "Devuelve la información detallada de un repositorio, incluyendo su estado de indexación, " +
                          "las células a las que está asociado y la lista de archivos que tiene en su carpeta S3 Workarea."
    )
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Información del repositorio obtenida",
                    content = @Content(schema = @Schema(implementation = RepositorioResponseDto.class))),
            @ApiResponse(responseCode = "404", description = "Repositorio no encontrado", content = @Content)
    })
    @GetMapping
    public Mono<RepositorioResponseDto> obtenerRepositorio(
            @Parameter(description = "URL del repositorio a consultar", required = true, example = "https://github.com/mi-org/mi-repo.git")
            @RequestParam("url") String urlRepo) {
        return gestionarRepositorioCasoUso.obtenerRepo(urlRepo);
    }

    @Operation(
            summary = "Indexar repositorio completo",
            description = "Dispara un proceso para indexar todos los archivos de un repositorio basándose en " +
                          "los metadatos actualmente guardados en la base de datos."
    )
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Proceso de indexación completado",
                    content = @Content(schema = @Schema(implementation = IndexacionCompletaResponseDto.class))),
            @ApiResponse(responseCode = "404", description = "Repositorio no encontrado", content = @Content)
    })
    @PostMapping("/indexar")
    public Mono<IndexacionCompletaResponseDto> indexarRepositorio(
            @Parameter(description = "URL del repositorio a indexar", required = true)
            @RequestParam("url") String urlRepo) {
        return gestionarRepositorioCasoUso.indexarRepositorioCompleto(urlRepo);
    }

    @Operation(
            summary = "Indexar un archivo específico",
            description = "Indexa o re-indexa un único archivo de un repositorio. " +
                          "Si se provee el contenido en Base64, se usa directamente; de lo contrario, se descarga desde Git."
    )
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Proceso de indexación finalizado (verificar el estado en la respuesta)",
                    content = @Content(schema = @Schema(implementation = IndexacionArchivoResponseDto.class))),
            @ApiResponse(responseCode = "404", description = "Repositorio no encontrado", content = @Content)
    })
    @PostMapping("/indexar-archivo")
    public Mono<IndexacionArchivoResponseDto> indexarArchivo(
            @Parameter(description = "Datos del archivo a indexar", required = true)
            @RequestBody IndexarArchivoRequestDto request) {
        return gestionarRepositorioCasoUso.indexarArchivo(request);
    }
}