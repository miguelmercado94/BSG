package com.bsg.soporterag.aplicacion.casodeuso.impl;

import com.bsg.soporterag.aplicacion.casodeuso.GestionarCelulaCasoUso;
import com.bsg.soporterag.aplicacion.dto.request.CelulaRequestDto;
import com.bsg.soporterag.aplicacion.dto.response.CelulaResponseDto;
import com.bsg.soporterag.aplicacion.mapperdto.CelulaMapperDto;
import com.bsg.soporterag.aplicacion.servicio.CelulaServicio;
import com.bsg.soporterag.aplicacion.servicio.RepositorioServicio;
import com.bsg.soporterag.dominio.modelo.Celula;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.util.stream.Collectors;

@Service
public class GestionarCelulaCasoUsoImpl implements GestionarCelulaCasoUso {

    private final CelulaServicio celulaServicio;
    private final RepositorioServicio repositorioServicio;
    private final CelulaMapperDto celulaMapperDto;

    public GestionarCelulaCasoUsoImpl(
            CelulaServicio celulaServicio,
            RepositorioServicio repositorioServicio,
            CelulaMapperDto celulaMapperDto) {
        this.celulaServicio = celulaServicio;
        this.repositorioServicio = repositorioServicio;
        this.celulaMapperDto = celulaMapperDto;
    }

    @Override
    public Mono<CelulaResponseDto> crear(CelulaRequestDto request) {
        Celula celula = celulaMapperDto.aDominio(request);
        return celulaServicio.crear(celula)
                .map(celulaMapperDto::aResponse);
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
        return celulaServicio.obtenerPorCodigo(codigo)
                .flatMap(celula -> celulaServicio.eliminar(celula.getId()));
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
        return repositorioServicio.obtenerTodoReposPorCelula(celula.getCodigo())
                .collect(Collectors.toSet())
                .map(repos -> {
                    celula.setRepositorios(repos);
                    return celulaMapperDto.aResponse(celula);
                });
    }
}