package com.bsg.soporterag.aplicacion.casodeuso.impl;

import com.bsg.soporterag.aplicacion.casodeuso.GestionarRepositorioCasoUso;
import com.bsg.soporterag.aplicacion.dto.request.ActualizarRepositorioRequestDto;
import com.bsg.soporterag.aplicacion.dto.request.IndexarArchivoRequestDto;
import com.bsg.soporterag.aplicacion.dto.request.RepositorioRequestDto;
import com.bsg.soporterag.aplicacion.dto.response.CelulaResumenDto;
import com.bsg.soporterag.aplicacion.dto.response.IndexacionArchivoResponseDto;
import com.bsg.soporterag.aplicacion.dto.response.IndexacionCompletaResponseDto;
import com.bsg.soporterag.aplicacion.dto.response.RepositorioResponseDto;
import com.bsg.soporterag.aplicacion.mapperdto.RepositorioMapperDto;
import com.bsg.soporterag.aplicacion.servicio.CelulaServicio;
import com.bsg.soporterag.aplicacion.servicio.RepositorioServicio;
import com.bsg.soporterag.aplicacion.servicio.ServicioBucketS3;
import com.bsg.soporterag.aplicacion.servicio.ServicioEmbedding;
import com.bsg.soporterag.aplicacion.servicio.ServicioJGit;
import com.bsg.soporterag.dominio.excepcion.CelulaNoEncontradaException;
import com.bsg.soporterag.dominio.modelo.CambiosEntreCommitsGit;
import com.bsg.soporterag.dominio.modelo.Repositorio;
import com.bsg.soporterag.dominio.modelo.RolBucketS3;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.time.Instant;
import java.util.ArrayList;
import java.util.Base64;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.stream.Collectors;

@Service
public class GestionarRepositorioCasoUsoImpl implements GestionarRepositorioCasoUso {

    private static final Logger log = LoggerFactory.getLogger(GestionarRepositorioCasoUsoImpl.class);

    private final RepositorioServicio repositorioServicio;
    private final RepositorioMapperDto repositorioMapperDto;
    private final ServicioJGit servicioJGit;
    private final ServicioBucketS3 servicioBucketS3;
    private final ServicioEmbedding servicioEmbedding;
    private final CelulaServicio celulaServicio;

    // Constructor...
    public GestionarRepositorioCasoUsoImpl(
            RepositorioServicio repositorioServicio,
            RepositorioMapperDto repositorioMapperDto,
            ServicioJGit servicioJGit,
            ServicioBucketS3 servicioBucketS3,
            ServicioEmbedding servicioEmbedding,
            CelulaServicio celulaServicio) {
        this.repositorioServicio = repositorioServicio;
        this.repositorioMapperDto = repositorioMapperDto;
        this.servicioJGit = servicioJGit;
        this.servicioBucketS3 = servicioBucketS3;
        this.servicioEmbedding = servicioEmbedding;
        this.celulaServicio = celulaServicio;
    }

    @Override
    public Mono<RepositorioResponseDto> obtenerRepo(String urlRepo) {
        String urlNormalizada = normalizarUrl(urlRepo);
        log.info("Obteniendo repositorio enriquecido | url={}", urlNormalizada);

        return repositorioServicio.obtenerRepo(urlNormalizada)
                .flatMap(this::enriquecerRepositorioConDependencias);
    }

    private Mono<RepositorioResponseDto> enriquecerRepositorioConDependencias(Repositorio repo) {
        Mono<List<CelulaResumenDto>> celulasMono = celulaServicio.listarCelulasPorNombreRepo(repo.getNombre())
                .map(c -> new CelulaResumenDto(c.getCodigo(), c.getNombre()))
                .collectList();

        Mono<List<String>> archivosS3Mono = servicioBucketS3.listarArchivos(RolBucketS3.WORKAREA, repo.getUrlFolderS3Workarea())
                .collectList()
                .defaultIfEmpty(new ArrayList<>());

        return Mono.zip(celulasMono, archivosS3Mono)
                .map(tuple -> {
                    RepositorioResponseDto dto = repositorioMapperDto.aResponse(repo);
                    dto.setCelulasAsociadas(tuple.getT1());
                    dto.setArchivosS3Workarea(tuple.getT2());
                    return dto;
                });
    }

    @Override
    public Mono<Void> desasociarRepositorioDeCelula(String urlRepo, String codigoCelula) {
        String urlNormalizada = normalizarUrl(urlRepo);
        log.info("Iniciando desasociación de repo {} de la célula {}", urlNormalizada, codigoCelula);

        return repositorioServicio.obtenerRepo(urlNormalizada)
                .flatMap(repo -> celulaServicio.desasociarRepositorio(codigoCelula, repo.getNombre())
                        .then(celulaServicio.contarAsociacionesParaRepo(repo.getNombre()))
                        .flatMap(conteo -> {
                            if (conteo == 0) {
                                log.info("El repositorio {} ya no tiene asociaciones. Iniciando eliminación completa.", repo.getNombre());
                                return eliminarRepoCompleto(repo);
                            } else {
                                log.info("El repositorio {} aún está asociado a {} célula(s).", repo.getNombre(), conteo);
                                return Mono.empty();
                            }
                        })
                ).then();
    }

    @Override
    public Mono<Void> eliminarRepo(String urlRepo) {
        String urlNormalizada = normalizarUrl(urlRepo);
        log.info("Iniciando eliminación completa de repositorio {}", urlNormalizada);
        return repositorioServicio.obtenerRepo(urlNormalizada)
                .flatMap(this::eliminarRepoCompleto);
    }

    private Mono<Void> eliminarRepoCompleto(Repositorio repo) {
        String nombreRepo = repo.getNombre();
        log.info("Ejecutando eliminación completa para repo={}", nombreRepo);

        Mono<Void> eliminarAsociaciones = celulaServicio.desasociarRepositorioDeTodasCelulas(nombreRepo)
                .doOnSuccess(v -> log.info("Asociaciones eliminadas para repo={}", nombreRepo));

        Mono<Void> eliminarEmbeddings = servicioEmbedding.eliminarTodosEmbeddingsPorRepo(nombreRepo)
                .doOnSuccess(v -> log.info("Embeddings eliminados para repo={}", nombreRepo));

        Mono<Void> eliminarS3 = servicioBucketS3.eliminarCarpeta(RolBucketS3.WORKAREA, repo.getUrlFolderS3Workarea())
                .doOnSuccess(v -> log.info("Carpeta S3 eliminada para repo={}", nombreRepo));

        Mono<Void> eliminarDocumento = repositorioServicio.eliminarRepo(repo.getUrl())
                .doOnSuccess(v -> log.info("Documento de repositorio eliminado para repo={}", nombreRepo));

        return Mono.when(eliminarAsociaciones, eliminarEmbeddings, eliminarS3)
                .then(eliminarDocumento)
                .doOnSuccess(v -> log.info("Eliminación completa finalizada para repo={}", nombreRepo));
    }
    
    // ... resto de métodos sin cambios
    @Override
    public Mono<RepositorioResponseDto> crearRepo(RepositorioRequestDto request) {
        validarNombre(request);
        validarCodigoCelula(request.getCodigoCelula());
        String url = normalizarUrl(request.getUrl());
        
        return celulaServicio.obtenerPorCodigo(request.getCodigoCelula())
                .switchIfEmpty(Mono.error(new CelulaNoEncontradaException(request.getCodigoCelula())))
                .flatMap(celula -> {
                    Repositorio repositorio = repositorioMapperDto.aDominioDesdeRequest(request, url);
                    log.info("Alta repositorio iniciada | nombre={} url={} celula={}", repositorio.getNombre(), url, request.getCodigoCelula());
                    
                    return servicioJGit.resolverRama(url, repositorio.getRamaPrincipal())
                            .doOnSubscribe(s -> log.info("Git: conectando e inventariando remoto | url={}", url))
                            .flatMap(rama -> {
                                repositorio.setRamaPrincipal(rama);
                                return Mono.zip(
                                        servicioJGit.obtenerUltimoCommit(url, rama),
                                        servicioJGit.extraerArbolRutas(url, rama));
                            })
                            .map(tuple -> {
                                repositorio.setUltimoCommit(tuple.getT1());
                                repositorioMapperDto.aplicarArbolRutas(repositorio, tuple.getT2());
                                repositorio.setFechaActualizacion(Instant.now());
                                return repositorio;
                            })
                            .doOnNext(repo -> log.info(
                                    "Git: inventario completado | url={} rama={} commit={} archivos={} carpetas={}",
                                    url,
                                    repo.getRamaPrincipal(),
                                    repo.getUltimoCommit(),
                                    repo.getFilesPath() != null ? repo.getFilesPath().size() : 0,
                                    repo.getFolderPath() != null ? repo.getFolderPath().size() : 0))
                            .flatMap(repo -> {
                                log.info(
                                        "S3: creando carpeta en workarea | prefijo={}",
                                        repo.getUrlFolderS3Workarea());
                                return servicioBucketS3
                                        .crearCarpeta(RolBucketS3.WORKAREA, repo.getUrlFolderS3Workarea())
                                        .doOnSuccess(v -> log.info(
                                                "S3: carpeta workarea creada | prefijo={}",
                                                repo.getUrlFolderS3Workarea()))
                                        .thenReturn(repo);
                            })
                            .flatMap(repo -> {
                                log.info(
                                        "Mongo: persistiendo repositorio | nombre={} url={}",
                                        repo.getNombre(),
                                        repo.getUrl());
                                return repositorioServicio.crearNuevoRepo(repo)
                                        .doOnSuccess(guardado -> log.info(
                                                "Mongo: repositorio guardado | nombre={} url={}",
                                                guardado.getNombre(),
                                                guardado.getUrl()));
                            })
                            .flatMap(repoGuardado -> {
                                log.info("Asociando repositorio {} a celula {}", repoGuardado.getNombre(), request.getCodigoCelula());
                                return celulaServicio.asociarRepositorio(request.getCodigoCelula(), repoGuardado.getNombre())
                                        .thenReturn(repoGuardado);
                            })
                            .map(repositorioMapperDto::aResponse);
                });
    }

    @Override
    public Mono<RepositorioResponseDto> actualizarRepo(ActualizarRepositorioRequestDto request) {
        String urlClave = normalizarUrl(request.getUrl());
        log.info("Actualizacion repositorio iniciada | url={}", urlClave);

        return repositorioServicio.obtenerRepo(urlClave)
                .flatMap(existente -> actualizarDescripcion(existente, request.getDescripcion()))
                .flatMap(repo -> procesarCambiosGit(repo, request.getRamaPrincipal()))
                .map(repositorioMapperDto::aResponse);
    }
    
    @Override
    public Mono<IndexacionCompletaResponseDto> indexarRepositorioCompleto(String urlRepo) {
        String urlNormalizada = normalizarUrl(urlRepo);
        log.info("Iniciando indexacion completa para repo={}", urlNormalizada);

        return repositorioServicio.obtenerRepo(urlNormalizada)
                .flatMap(repo -> {
                    if (repo.getFilesPath() == null || repo.getFilesPath().isEmpty()) {
                        log.warn("Repo={} no tiene archivos en su metadata para indexar.", repo.getNombre());
                        IndexacionCompletaResponseDto response = new IndexacionCompletaResponseDto();
                        response.setRepositorio(repositorioMapperDto.aResponse(repo));
                        response.setArchivosIndexados(new ArrayList<>());
                        response.setArchivosFallidos(new HashMap<>());
                        return Mono.just(response);
                    }

                    log.info("Repo={} tiene {} archivos. Iniciando proceso de embedding concurrente...", repo.getNombre(), repo.getFilesPath().size());

                    record ResultadoIndexacion(String filePath, boolean exitoso, String mensajeError) {}

                    return Flux.fromIterable(repo.getFilesPath())
                            // flatMap con concurrency 3: Procesa hasta 3 archivos a la vez.
                            .flatMap(filePath -> 
                                embedirArchivoIndividualLanzandoError(repo, filePath)
                                    .thenReturn(new ResultadoIndexacion(filePath, true, null))
                                    .onErrorResume(e -> {
                                        String mensajeLimpio = extraerMensajeErrorLimpio(e);
                                        log.warn("Fallo al intentar embeber el archivo '{}' en repo '{}'. Causa: {}.", filePath, repo.getNombre(), mensajeLimpio);
                                        return Mono.just(new ResultadoIndexacion(filePath, false, mensajeLimpio));
                                    }),
                            3) // concurrency level
                            .collectList()
                            .flatMap(resultados -> {
                                List<String> exitosos = new ArrayList<>();
                                Map<String, String> fallidos = new HashMap<>();
                                for (ResultadoIndexacion res : resultados) {
                                    if (res.exitoso()) {
                                        exitosos.add(res.filePath());
                                    } else {
                                        fallidos.put(res.filePath(), res.mensajeError());
                                    }
                                }

                                Mono<Repositorio> repoActualizadoMono = Mono.just(repo);
                                if (!exitosos.isEmpty() && !repo.isIndexado()) {
                                    repoActualizadoMono = marcarComoIndexado(repo);
                                }

                                return repoActualizadoMono.map(repoActualizado -> {
                                    IndexacionCompletaResponseDto response = new IndexacionCompletaResponseDto();
                                    response.setRepositorio(repositorioMapperDto.aResponse(repoActualizado));
                                    response.setArchivosIndexados(exitosos);
                                    response.setArchivosFallidos(fallidos);
                                    return response;
                                });
                            });
                });
    }

    @Override
    public Mono<IndexacionArchivoResponseDto> indexarArchivo(IndexarArchivoRequestDto request) {
        String urlNormalizada = normalizarUrl(request.getUrlRepo());
        String filePath = request.getFilePath();
        log.info("Iniciando indexacion individual de archivo={} en repo={}", filePath, urlNormalizada);

        Mono<byte[]> contenidoMono;

        if (StringUtils.hasText(request.getContenidoBase64())) {
            log.info("Utilizando contenido Base64 provisto en el request para el archivo={}", filePath);
            contenidoMono = Mono.fromCallable(() -> Base64.getDecoder().decode(request.getContenidoBase64()));
        } else {
            log.info("Contenido no provisto, descargando desde Git el archivo={}", filePath);
            contenidoMono = repositorioServicio.obtenerRepo(urlNormalizada)
                    .flatMap(repo -> servicioJGit.extraerContenidoArchivo(repo.getUrl(), repo.getRamaPrincipal(), filePath));
        }

        return repositorioServicio.obtenerRepo(urlNormalizada)
                .flatMap(repo -> contenidoMono
                        .flatMap(contenido -> servicioEmbedding.actualizarEmbedding(false, repo.getNombre(), filePath, contenido))
                        .thenReturn(crearRespuestaArchivo(filePath, true, "Archivo indexado correctamente."))
                )
                .onErrorResume(e -> {
                    String mensajeLimpio = extraerMensajeErrorLimpio(e);
                    log.error("Error en la indexación del archivo {}: {}", filePath, mensajeLimpio);
                    return Mono.just(crearRespuestaArchivo(filePath, false, mensajeLimpio));
                });
    }
    
    private IndexacionArchivoResponseDto crearRespuestaArchivo(String filePath, boolean exitoso, String mensaje) {
        IndexacionArchivoResponseDto response = new IndexacionArchivoResponseDto();
        response.setFilePath(filePath);
        response.setExitoso(exitoso);
        response.setMensaje(mensaje);
        return response;
    }

    private String extraerMensajeErrorLimpio(Throwable e) {
        String msg = e.getMessage() != null ? e.getMessage() : "Error desconocido";
        if (msg.contains("the input length exceeds the context length")) {
            return "El archivo excede la longitud máxima de contexto permitida por el modelo.";
        }
        if (msg.contains("PreparedStatementCallback") || msg.contains("SQL [")) {
            // Extraer una causa más amigable si es posible, de lo contrario un mensaje genérico de BD
            return "Error de persistencia vectorial. Posible conflicto de datos o archivo demasiado grande.";
        }
        return msg;
    }

    private Mono<Repositorio> actualizarDescripcion(Repositorio existente, String nuevaDescripcion) {
        if (StringUtils.hasText(nuevaDescripcion)) {
            existente.setDescripcion(nuevaDescripcion);
            log.info("Descripcion actualizada para repo={} a '{}'", existente.getNombre(), nuevaDescripcion);
        }
        return Mono.just(existente); // Se guarda al final
    }

    private Mono<Repositorio> procesarCambiosGit(Repositorio repo, String ramaSolicitada) {
        String url = repo.getUrl();
        return servicioJGit.resolverRama(url, ramaSolicitada)
                .flatMap(ramaResuelta -> servicioJGit.obtenerUltimoCommit(url, ramaResuelta)
                        .flatMap(commitRemoto -> {
                            boolean mismaRama = Objects.equals(repo.getRamaPrincipal(), ramaResuelta);
                            boolean mismoCommit = Objects.equals(repo.getUltimoCommit(), commitRemoto);

                            if (mismaRama && mismoCommit) {
                                log.info("Repo={} esta actualizado. rama={} commit={}",
                                        repo.getNombre(), ramaResuelta, commitRemoto);
                                return repositorioServicio.actualizarRepo(repo, repo.getUrl());
                            }

                            log.info("Repo={} detecto cambios. ramaLocal={} ramaRemota={} commitLocal={} commitRemoto={}",
                                    repo.getNombre(), repo.getRamaPrincipal(), ramaResuelta,
                                    repo.getUltimoCommit(), commitRemoto);

                            return sincronizarDiferencias(repo, ramaResuelta, commitRemoto);
                        })
                );
    }

    private Mono<Repositorio> sincronizarDiferencias(Repositorio repo, String ramaNueva, String commitNuevo) {
        String commitAntiguo = repo.getUltimoCommit();
        
        return servicioJGit.listarRutasCambiadas(repo.getUrl(), ramaNueva, commitAntiguo, commitNuevo)
                .flatMap(cambios -> {
                    if (!repo.isIndexado()) {
                        log.info("Repo={} no esta indexado. Solo se actualizan metadatos en BD.", repo.getNombre());
                        return actualizarMetadatosYGuardar(repo, ramaNueva, commitNuevo);
                    }

                    log.info("Repo={} indexado. Sincronizando embeddings...", repo.getNombre());
                    return procesarEmbeddingsCambios(repo, ramaNueva, cambios)
                            .then(actualizarMetadatosYGuardar(repo, ramaNueva, commitNuevo));
                });
    }

    private Mono<Void> procesarEmbeddingsCambios(Repositorio repo, String rama, CambiosEntreCommitsGit cambios) {
        String url = repo.getUrl();
        String nombreRepo = repo.getNombre();

        Mono<Void> eliminaciones = Flux.fromIterable(cambios.rutasEliminadas() != null ? cambios.rutasEliminadas() : java.util.List.of())
                .doOnNext(ruta -> log.info("Eliminando embedding: {}", ruta))
                .flatMap(ruta -> servicioEmbedding.eliminarEmbedding(false, nombreRepo, ruta))
                .then();

        Mono<Void> agregaciones = Flux.fromIterable(cambios.rutasAgregadas() != null ? cambios.rutasAgregadas() : java.util.List.of())
                .doOnNext(ruta -> log.info("Agregando embedding: {}", ruta))
                .flatMap(ruta -> servicioJGit.extraerContenidoArchivo(url, rama, ruta)
                        .flatMap(contenido -> servicioEmbedding.embedirArchivo(false, nombreRepo, ruta, contenido)))
                .then();

        Mono<Void> modificaciones = Flux.fromIterable(cambios.rutasModificadas() != null ? cambios.rutasModificadas() : java.util.List.of())
                .doOnNext(ruta -> log.info("Actualizando embedding: {}", ruta))
                .flatMap(ruta -> servicioJGit.extraerContenidoArchivo(url, rama, ruta)
                        .flatMap(contenido -> servicioEmbedding.actualizarEmbedding(false, nombreRepo, ruta, contenido)))
                .then();

        return Mono.when(eliminaciones, agregaciones, modificaciones);
    }

    private Mono<Repositorio> actualizarMetadatosYGuardar(Repositorio repo, String ramaNueva, String commitNuevo) {
        repo.setRamaPrincipal(ramaNueva);
        repo.setUltimoCommit(commitNuevo);
        repo.setFechaActualizacion(Instant.now());
        
        return repositorioServicio.actualizarRepo(repo, repo.getUrl())
                .doOnSuccess(r -> log.info("Metadatos actualizados en BD para repo={}", r.getNombre()));
    }
    
    private Mono<Void> embedirArchivoIndividualLanzandoError(Repositorio repo, String filePath) {
        return servicioJGit.extraerContenidoArchivo(repo.getUrl(), repo.getRamaPrincipal(), filePath)
                .flatMap(contenido -> {
                    log.info("Procesando embedding para archivo: {}", filePath);
                    return servicioEmbedding.actualizarEmbedding(false, repo.getNombre(), filePath, contenido)
                            .doOnSuccess(v -> log.info("Embedding exitoso para archivo: {}", filePath));
                });
    }
    
    private Mono<Repositorio> marcarComoIndexado(Repositorio repo) {
        repo.setIndexado(true);
        return repositorioServicio.actualizarRepo(repo, repo.getUrl())
                .doOnSuccess(r -> log.info("Proceso de indexación completa finalizado. Repo={} marcado como indexado.", r.getNombre()));
    }

    private void validarNombre(RepositorioRequestDto request) {
        if (!StringUtils.hasText(request.getNombre())) {
            throw new IllegalArgumentException("El nombre del repositorio es obligatorio");
        }
    }

    private void validarCodigoCelula(String codigoCelula) {
        if (!StringUtils.hasText(codigoCelula)) {
            throw new IllegalArgumentException("El código de la célula es obligatorio");
        }
    }

    private String normalizarUrl(String url) {
        if (!StringUtils.hasText(url)) {
            throw new IllegalArgumentException("La URL del repositorio es obligatoria");
        }
        return url.trim();
    }
}