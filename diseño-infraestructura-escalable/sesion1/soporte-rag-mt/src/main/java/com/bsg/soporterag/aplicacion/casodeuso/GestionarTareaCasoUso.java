package com.bsg.soporterag.aplicacion.casodeuso;

import com.bsg.soporterag.aplicacion.dto.request.ActualizarEstadoTareaRequestDto;
import com.bsg.soporterag.aplicacion.dto.request.ActualizarTareaRequestDto;
import com.bsg.soporterag.aplicacion.dto.request.CrearTareaRequestDto;
import com.bsg.soporterag.aplicacion.dto.response.TareaResponseDto;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

public interface GestionarTareaCasoUso {

    Mono<TareaResponseDto> crearTarea(CrearTareaRequestDto request);

    Mono<TareaResponseDto> actualizarTarea(String codigoTarea, ActualizarTareaRequestDto request);

    Mono<Void> eliminarTarea(String codigoTarea);

    Flux<TareaResponseDto> obtenerTareasPorUsuario(String codigoUsuario);

    Mono<TareaResponseDto> actualizarEstado(String codigoTarea, ActualizarEstadoTareaRequestDto request);
}
