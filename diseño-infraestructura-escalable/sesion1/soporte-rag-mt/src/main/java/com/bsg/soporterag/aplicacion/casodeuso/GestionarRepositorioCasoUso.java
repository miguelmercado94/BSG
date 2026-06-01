package com.bsg.soporterag.aplicacion.casodeuso;

import com.bsg.soporterag.aplicacion.dto.request.ActualizarRepositorioRequestDto;
import com.bsg.soporterag.aplicacion.dto.request.IndexarArchivoRequestDto;
import com.bsg.soporterag.aplicacion.dto.request.RepositorioRequestDto;
import com.bsg.soporterag.aplicacion.dto.response.IndexacionArchivoResponseDto;
import com.bsg.soporterag.aplicacion.dto.response.IndexacionCompletaResponseDto;
import com.bsg.soporterag.aplicacion.dto.response.RepositorioResponseDto;
import reactor.core.publisher.Mono;

public interface GestionarRepositorioCasoUso {

    Mono<RepositorioResponseDto> crearRepo(RepositorioRequestDto request);

    Mono<RepositorioResponseDto> actualizarRepo(ActualizarRepositorioRequestDto request);

    Mono<Void> eliminarRepo(String urlRepo);

    Mono<Void> desasociarRepositorioDeCelula(String urlRepo, String codigoCelula);

    Mono<RepositorioResponseDto> obtenerRepo(String urlRepo);

    Mono<IndexacionCompletaResponseDto> indexarRepositorioCompleto(String urlRepo);

    Mono<IndexacionArchivoResponseDto> indexarArchivo(IndexarArchivoRequestDto request);
}
