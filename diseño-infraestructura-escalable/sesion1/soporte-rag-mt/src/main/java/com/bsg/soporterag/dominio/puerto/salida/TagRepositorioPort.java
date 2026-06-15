package com.bsg.soporterag.dominio.puerto.salida;

import com.bsg.soporterag.dominio.modelo.Tag;
import com.bsg.soporterag.dominio.modelo.UrlToolTag;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

public interface TagRepositorioPort {

    // --- Operaciones CRUD sobre la colección global de Tags ---
    Mono<Tag> guardar(Tag tag);
    Flux<Tag> buscarPorTags(String... nombresTags);
    Flux<Tag> buscarTodos();
    Mono<Void> eliminarPorTag(String nombreTag);

    // --- Operaciones sobre la lista embebida de UrlToolTag ---
    Mono<Void> agregarUrlTool(String nombreTag, UrlToolTag urlTool);
    Mono<Void> eliminarUrlTool(String nombreTag, String urlTool);
}
