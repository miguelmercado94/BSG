package com.bsg.soporterag.aplicacion.servicio;

import com.bsg.soporterag.dominio.modelo.Tag;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

public interface TagServicio {

    // --- Operaciones sobre la colección global de Tags ---
    Mono<Tag> crearTag(Tag tag);
    Mono<Tag> actualizarTag(String nombreTag, Tag tag);
    Mono<Void> eliminarTag(String nombreTag);
    Flux<Tag> obtenerTodosLosTags();
    Flux<Tag> obtenerTagsPorNombres(String... nombresTags);

    // --- Operaciones sobre la lista embebida de UrlToolTag ---
    Mono<Void> agregarUrlTool(String nombreTag, String urlTool, String contextoUrl);
    Mono<Void> eliminarUrlTool(String nombreTag, String urlTool);
}
