package com.bsg.soporterag.aplicacion.casodeuso;

import com.bsg.soporterag.aplicacion.dto.request.CelulaRequestDto;
import com.bsg.soporterag.aplicacion.dto.response.CelulaResponseDto;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

public interface GestionarCelulaCasoUso {
    Mono<CelulaResponseDto> crear(CelulaRequestDto request);
    Mono<CelulaResponseDto> actualizar(String codigo, CelulaRequestDto request);
    Mono<Void> eliminar(String codigo);
    Mono<CelulaResponseDto> obtenerPorCodigo(String codigo);
    Flux<CelulaResponseDto> listarTodas();
}