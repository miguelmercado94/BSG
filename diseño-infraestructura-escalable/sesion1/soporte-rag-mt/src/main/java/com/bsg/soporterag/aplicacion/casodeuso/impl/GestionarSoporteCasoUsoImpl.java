package com.bsg.soporterag.aplicacion.casodeuso.impl;

import com.bsg.soporterag.aplicacion.casodeuso.GestionarSoporteCasoUso;
import com.bsg.soporterag.aplicacion.dto.request.ActualizarSoporteRequestDto;
import com.bsg.soporterag.aplicacion.dto.request.CrearSoporteRequestDto;
import com.bsg.soporterag.aplicacion.dto.response.SoporteResponseDto;
import com.bsg.soporterag.aplicacion.mapperdto.SoporteMapperDto;
import com.bsg.soporterag.aplicacion.servicio.DocumentoSoporteServicio;
import com.bsg.soporterag.aplicacion.servicio.RepositorioServicio;
import com.bsg.soporterag.aplicacion.servicio.ServicioBucketS3;
import com.bsg.soporterag.aplicacion.servicio.ServicioEmbedding;
import com.bsg.soporterag.dominio.modelo.DocumentoSoporte;
import com.bsg.soporterag.dominio.modelo.RolBucketS3;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.time.Instant;
import java.util.Base64;

@Service
public class GestionarSoporteCasoUsoImpl implements GestionarSoporteCasoUso {

    private static final Logger log = LoggerFactory.getLogger(GestionarSoporteCasoUsoImpl.class);

    private final DocumentoSoporteServicio documentoSoporteServicio;
    private final RepositorioServicio repositorioServicio;
    private final ServicioEmbedding servicioEmbedding;
    private final ServicioBucketS3 servicioBucketS3;
    private final SoporteMapperDto soporteMapperDto;

    public GestionarSoporteCasoUsoImpl(
            DocumentoSoporteServicio documentoSoporteServicio,
            RepositorioServicio repositorioServicio,
            ServicioEmbedding servicioEmbedding,
            ServicioBucketS3 servicioBucketS3,
            SoporteMapperDto soporteMapperDto) {
        this.documentoSoporteServicio = documentoSoporteServicio;
        this.repositorioServicio = repositorioServicio;
        this.servicioEmbedding = servicioEmbedding;
        this.servicioBucketS3 = servicioBucketS3;
        this.soporteMapperDto = soporteMapperDto;
    }

    @Override
    public Mono<SoporteResponseDto> crear(CrearSoporteRequestDto request) {
        if (!StringUtils.hasText(request.getContenidoBase64())) {
            return Mono.error(new IllegalArgumentException("El contenido del archivo en Base64 es obligatorio para la creación."));
        }
        if (!StringUtils.hasText(request.getNombreArchivo()) || !request.getNombreArchivo().endsWith(".md")) {
            return Mono.error(new IllegalArgumentException("El nombre del archivo es obligatorio y debe tener extensión .md"));
        }

        return repositorioServicio.obtenerRepo(request.getUrlRepo())
                .flatMap(repositorio -> {
                    String s3Path = repositorio.getUrlFolderS3Workarea() + request.getCodigo() + "-" + request.getNombreArchivo();
                    DocumentoSoporte nuevoSoporte = soporteMapperDto.aDominio(request, repositorio, s3Path);
                    byte[] contenido;
                    try {
                        contenido = Base64.getDecoder().decode(request.getContenidoBase64());
                    } catch (IllegalArgumentException e) {
                        return Mono.error(new IllegalArgumentException("El contenido Base64 no es válido"));
                    }

                    return servicioBucketS3.crearArchivo(RolBucketS3.WORKAREA, s3Path, contenido, "text/markdown")
                            .then(documentoSoporteServicio.crear(nuevoSoporte))
                            .flatMap(soporteGuardado -> 
                                servicioEmbedding.embedirArchivo(true, request.getUrlRepo(), soporteGuardado.codigoSoporte(), contenido)
                                    .onErrorResume(e -> {
                                        log.error("Fallo el embedding para el soporte {}, haciendo rollback...", request.getCodigo());
                                        return servicioBucketS3.eliminarCarpeta(RolBucketS3.WORKAREA, s3Path)
                                                .onErrorResume(e2 -> Mono.empty())
                                                .then(documentoSoporteServicio.eliminar(soporteGuardado.codigoSoporte()))
                                                .onErrorResume(e3 -> Mono.empty())
                                                .then(Mono.error(new RuntimeException("Fallo al procesar el embedding: " + e.getMessage())));
                                    })
                                    .thenReturn(soporteGuardado)
                            );
                })
                .flatMap(this::enriquecerConPresigned);
    }

    @Override
    public Mono<SoporteResponseDto> actualizar(String codigo, ActualizarSoporteRequestDto request) {
        return documentoSoporteServicio.obtenerPorCodigo(codigo)
                .flatMap(existente -> {
                    Mono<String> pathMono = Mono.just(existente.urlBucketS3());
                    if (StringUtils.hasText(request.getNombreArchivo())) {
                        if (!request.getNombreArchivo().endsWith(".md")) {
                            return Mono.error(new IllegalArgumentException("El nombre del archivo debe tener extensión .md"));
                        }
                        pathMono = repositorioServicio.obtenerRepo(existente.urlRepo())
                            .map(repo -> repo.getUrlFolderS3Workarea() + existente.codigoSoporte() + "-" + request.getNombreArchivo());
                    }

                    return pathMono.flatMap(resolvedPath -> {
                        Mono<Void> s3AndEmbeddingTask = Mono.empty();
                        if (StringUtils.hasText(request.getContenidoBase64())) {
                             byte[] contenido = Base64.getDecoder().decode(request.getContenidoBase64());
                             Mono<Void> borrarViejoS3 = existente.urlBucketS3().equals(resolvedPath) ? Mono.empty() : servicioBucketS3.eliminarCarpeta(RolBucketS3.WORKAREA, existente.urlBucketS3());
                             s3AndEmbeddingTask = borrarViejoS3
                                     .then(servicioBucketS3.crearArchivo(RolBucketS3.WORKAREA, resolvedPath, contenido, "text/markdown"))
                                     .then(servicioEmbedding.actualizarEmbedding(true, existente.urlRepo(), existente.codigoSoporte(), contenido));
                        }

                        DocumentoSoporte actualizado = new DocumentoSoporte(
                                existente.id(),
                                existente.codigoSoporte(),
                                existente.urlRepo(),
                                StringUtils.hasText(request.getNombre()) ? request.getNombre() : existente.nombre(),
                                StringUtils.hasText(request.getDescripcion()) ? request.getDescripcion() : existente.descripcion(),
                                existente.namespaceVectorial(),
                                resolvedPath,
                                existente.bucketRol(),
                                true,
                                Instant.now()
                        );

                        return s3AndEmbeddingTask
                                .then(documentoSoporteServicio.actualizar(codigo, actualizado));
                    });
                })
                .flatMap(this::enriquecerConPresigned);
    }

    @Override
    public Mono<SoporteResponseDto> eliminar(String codigo) {
        return documentoSoporteServicio.obtenerPorCodigo(codigo)
                .flatMap(soporte -> servicioEmbedding.eliminarEmbedding(true, soporte.urlRepo(), soporte.codigoSoporte())
                        .then(servicioBucketS3.eliminarCarpeta(RolBucketS3.WORKAREA, soporte.urlBucketS3()))
                        .then(documentoSoporteServicio.eliminar(codigo))
                        .then(enriquecerConPresigned(soporte))
                );
    }

    @Override
    public Mono<SoporteResponseDto> obtenerPorCodigo(String codigo) {
        return documentoSoporteServicio.obtenerPorCodigo(codigo)
                .flatMap(this::enriquecerConPresigned);
    }

    @Override
    public Flux<SoporteResponseDto> obtenerTodosPorUrlRepo(String urlRepo) {
        return documentoSoporteServicio.obtenerTodosPorUrlRepo(urlRepo)
                .flatMap(this::enriquecerConPresigned);
    }

    private Mono<SoporteResponseDto> enriquecerConPresigned(DocumentoSoporte soporte) {
        return servicioBucketS3.generarUrlLectura(soporte.bucketRol(), soporte.urlBucketS3())
                .defaultIfEmpty("") // Si falla o no hay, devuelve string vacío
                .map(presignedUrl -> {
                    SoporteResponseDto dto = soporteMapperDto.aResponse(soporte, soporte.urlRepo());
                    dto.setUrlS3(presignedUrl);
                    return dto;
                });
    }
}
