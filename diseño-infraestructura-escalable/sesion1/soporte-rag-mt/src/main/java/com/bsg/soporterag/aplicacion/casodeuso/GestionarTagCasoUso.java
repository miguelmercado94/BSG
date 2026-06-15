package com.bsg.soporterag.aplicacion.casodeuso;

import com.bsg.soporterag.aplicacion.dto.request.ActualizarTagRequestDto;
import com.bsg.soporterag.aplicacion.dto.request.CrearTagRequestDto;
import com.bsg.soporterag.aplicacion.dto.response.ActualizarTagResponseDto;
import com.bsg.soporterag.aplicacion.dto.response.TagResponseDto;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

public interface GestionarTagCasoUso {

    Mono<TagResponseDto> crearTag(CrearTagRequestDto request);

    Mono<ActualizarTagResponseDto> actualizarTag(String nombreTag, ActualizarTagRequestDto request);

    Mono<Void> eliminarTag(String nombreTag);

    Flux<TagResponseDto> obtenerTodosTags();

    Mono<TagResponseDto> obtenerTagPorNombre(String nombreTag);

    Mono<Void> agregarUrlTool(String nombreTag, String urlTool, String contextoUrl);

    Mono<Void> eliminarUrlTool(String nombreTag, String urlTool);
}
