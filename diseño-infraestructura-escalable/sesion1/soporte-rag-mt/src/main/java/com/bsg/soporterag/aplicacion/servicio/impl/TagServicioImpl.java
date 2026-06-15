package com.bsg.soporterag.aplicacion.servicio.impl;

import com.bsg.soporterag.aplicacion.servicio.TagServicio;
import com.bsg.soporterag.dominio.modelo.Tag;
import com.bsg.soporterag.dominio.modelo.UrlToolTag;
import com.bsg.soporterag.dominio.puerto.salida.TagRepositorioPort;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

@Service
public class TagServicioImpl implements TagServicio {

    private final TagRepositorioPort tagRepositorioPort;

    public TagServicioImpl(TagRepositorioPort tagRepositorioPort) {
        this.tagRepositorioPort = tagRepositorioPort;
    }

    @Override
    public Mono<Tag> crearTag(Tag tag) {
        if (!StringUtils.hasText(tag.getTag())) {
            return Mono.error(new IllegalArgumentException("El nombre del tag es obligatorio"));
        }
        return tagRepositorioPort.guardar(tag);
    }

    @Override
    public Mono<Tag> actualizarTag(String nombreTag, Tag tagActualizado) {
        return tagRepositorioPort.buscarPorTags(nombreTag)
                .next()
                .flatMap(existente -> {
                    Tag modificado = new Tag(
                        existente.getId(),
                        existente.getTag(), // No se permite cambiar el nombre del tag
                        tagActualizado.getDescripcionTag(),
                        tagActualizado.isHabilitado(),
                        existente.getUrlToolTag() // La actualización de Urls es otra operación
                    );
                    return tagRepositorioPort.guardar(modificado);
                })
                .switchIfEmpty(Mono.error(new IllegalArgumentException("No se encontró el tag: " + nombreTag)));
    }

    @Override
    public Mono<Void> eliminarTag(String nombreTag) {
        // Aquí se podría añadir lógica para desasociar este tag de todos los repositorios que lo usan
        return tagRepositorioPort.eliminarPorTag(nombreTag);
    }

    @Override
    public Flux<Tag> obtenerTodosLosTags() {
        return tagRepositorioPort.buscarTodos();
    }

    @Override
    public Flux<Tag> obtenerTagsPorNombres(String... nombresTags) {
        return tagRepositorioPort.buscarPorTags(nombresTags);
    }

    @Override
    public Mono<Void> agregarUrlTool(String nombreTag, String urlTool, String contextoUrl) {
        if (!StringUtils.hasText(urlTool)) {
            return Mono.error(new IllegalArgumentException("La URL de la herramienta no puede estar vacía"));
        }
        UrlToolTag nuevoUrlTool = new UrlToolTag(urlTool, contextoUrl);
        return tagRepositorioPort.agregarUrlTool(nombreTag, nuevoUrlTool);
    }

    @Override
    public Mono<Void> eliminarUrlTool(String nombreTag, String urlTool) {
        return tagRepositorioPort.eliminarUrlTool(nombreTag, urlTool);
    }
}
