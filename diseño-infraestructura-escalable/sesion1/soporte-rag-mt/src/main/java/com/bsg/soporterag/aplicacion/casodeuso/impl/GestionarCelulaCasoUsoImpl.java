package com.bsg.soporterag.aplicacion.casodeuso.impl;

import com.bsg.soporterag.aplicacion.casodeuso.GestionarCelulaCasoUso;
import com.bsg.soporterag.aplicacion.casodeuso.GestionarRepositorioCasoUso;
import com.bsg.soporterag.aplicacion.dto.request.CelulaRequestDto;
import com.bsg.soporterag.aplicacion.dto.response.CelulaResponseDto;
import com.bsg.soporterag.aplicacion.mapperdto.CelulaMapperDto;
import com.bsg.soporterag.aplicacion.servicio.CelulaServicio;
import com.bsg.soporterag.aplicacion.servicio.RepositorioServicio;
import com.bsg.soporterag.dominio.modelo.Celula;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.annotation.Lazy;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

@Service
public class GestionarCelulaCasoUsoImpl implements GestionarCelulaCasoUso {

    private static final Logger log = LoggerFactory.getLogger(GestionarCelulaCasoUsoImpl.class);

    private final CelulaServicio celulaServicio;
    private final RepositorioServicio repositorioServicio;
    private final CelulaMapperDto celulaMapperDto;
    private final GestionarRepositorioCasoUso gestionarRepositorioCasoUso;

    public GestionarCelulaCasoUsoImpl(
            CelulaServicio celulaServicio,
            RepositorioServicio repositorioServicio,
            CelulaMapperDto celulaMapperDto,
            @Lazy GestionarRepositorioCasoUso gestionarRepositorioCasoUso) {
        this.celulaServicio = celulaServicio;
        this.repositorioServicio = repositorioServicio;
        this.celulaMapperDto = celulaMapperDto;
        this.gestionarRepositorioCasoUso = gestionarRepositorioCasoUso;
    }

    @Override
    public Mono<CelulaResponseDto> crear(CelulaRequestDto request) {
        if (!org.springframework.util.StringUtils.hasText(request.getCodigo())) {
            return Mono.error(new IllegalArgumentException("El código de la célula es obligatorio"));
        }
        return celulaServicio.obtenerPorCodigo(request.getCodigo().trim())
                .flatMap(existente -> Mono.<CelulaResponseDto>error(
                        new IllegalArgumentException("Ya existe una célula con el código: " + request.getCodigo())))
                .switchIfEmpty(Mono.defer(() -> {
                    Celula celula = celulaMapperDto.aDominio(request);
                    return celulaServicio.crear(celula)
                            .map(celulaMapperDto::aResponse);
                }));
    }

    @Override
    public Mono<CelulaResponseDto> actualizar(String codigo, CelulaRequestDto request) {
        return celulaServicio.obtenerPorCodigo(codigo)
                .flatMap(celulaExistente -> {
                    celulaMapperDto.actualizarDominio(celulaExistente, request);
                    return celulaServicio.actualizar(celulaExistente.getId(), celulaExistente);
                })
                .flatMap(this::enriquecerCelulaConRepositorios);
    }

    @Override
    public Mono<Void> eliminar(String codigo) {
        log.info("Iniciando eliminacion de celula codigo={}", codigo);
        return celulaServicio.obtenerPorCodigo(codigo)
                .flatMap(celula -> {
                    // 1. Obtener todos los nombres de repositorios asociados a esta célula
                    return celulaServicio.listarNombresRepoPorCodigoCelula(celula.getCodigo())
                            .collectList()
                            .flatMap(nombresRepos -> {
                                log.info("Celula={} tiene asociados los repositorios: {}. Procesando eliminacion/desasociacion...", celula.getCodigo(), nombresRepos);
                                return Flux.fromIterable(nombresRepos)
                                        .flatMap(nombreRepo -> {
                                            return celulaServicio.contarAsociacionesParaRepo(nombreRepo)
                                                    .flatMap(count -> {
                                                        if (count <= 1) {
                                                            log.info("Repo={} esta asociado únicamente a esta célula. Eliminando repositorio completo...", nombreRepo);
                                                            return repositorioServicio.obtenerRepoPorNombre(nombreRepo)
                                                                    .flatMap(repo -> gestionarRepositorioCasoUso.eliminarRepo(repo.getUrl()))
                                                                    .onErrorResume(e -> {
                                                                        log.error("Error al eliminar repo={} huerfano", nombreRepo, e);
                                                                        return Mono.empty();
                                                                    });
                                                        } else {
                                                            log.info("Repo={} esta asociado a otras células. Desasociando de celula={}...", nombreRepo, celula.getCodigo());
                                                            return celulaServicio.desasociarRepositorio(celula.getCodigo(), nombreRepo);
                                                        }
                                                    });
                                        })
                                        .then();
                            })
                            .then(celulaServicio.eliminar(celula.getId()));
                });
    }

    @Override
    public Mono<CelulaResponseDto> obtenerPorCodigo(String codigo) {
        return celulaServicio.obtenerPorCodigo(codigo)
                .flatMap(this::enriquecerCelulaConRepositorios);
    }

    @Override
    public Flux<CelulaResponseDto> listarTodas() {
        return celulaServicio.listarTodas()
                .flatMap(this::enriquecerCelulaConRepositorios);
    }

    private Mono<CelulaResponseDto> enriquecerCelulaConRepositorios(Celula celula) {
        return repositorioServicio.obtenerTodosPorCelula(celula.getCodigo())
                .collectList()
                .map(repos -> {
                    celula.setRepositorios(new java.util.HashSet<>(repos));
                    return celulaMapperDto.aResponse(celula);
                });
    }
}