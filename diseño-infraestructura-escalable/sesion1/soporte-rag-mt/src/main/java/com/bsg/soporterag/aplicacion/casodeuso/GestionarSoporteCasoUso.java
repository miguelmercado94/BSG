package com.bsg.soporterag.aplicacion.casodeuso;

import com.bsg.soporterag.aplicacion.dto.request.ActualizarSoporteRequestDto;
import com.bsg.soporterag.aplicacion.dto.request.CrearSoporteRequestDto;
import com.bsg.soporterag.aplicacion.dto.response.SoporteResponseDto;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

public interface GestionarSoporteCasoUso {

    Mono<SoporteResponseDto> crear(CrearSoporteRequestDto request);

    Mono<SoporteResponseDto> actualizar(String codigo, ActualizarSoporteRequestDto request);

    Mono<SoporteResponseDto> eliminar(String codigo);

    Mono<SoporteResponseDto> obtenerPorCodigo(String codigo);

    Flux<SoporteResponseDto> obtenerTodosPorUrlRepo(String urlRepo);
}
