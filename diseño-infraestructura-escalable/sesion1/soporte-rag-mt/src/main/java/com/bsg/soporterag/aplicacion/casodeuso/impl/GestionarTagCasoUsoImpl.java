package com.bsg.soporterag.aplicacion.casodeuso.impl;

import com.bsg.soporterag.aplicacion.casodeuso.GestionarTagCasoUso;
import com.bsg.soporterag.aplicacion.dto.request.ActualizarTagRequestDto;
import com.bsg.soporterag.aplicacion.dto.request.CrearTagRequestDto;
import com.bsg.soporterag.aplicacion.dto.response.ActualizarTagResponseDto;
import com.bsg.soporterag.aplicacion.dto.response.TagResponseDto;
import com.bsg.soporterag.aplicacion.mapperdto.TagDtoMapper;
import com.bsg.soporterag.aplicacion.servicio.RepositorioServicio;
import com.bsg.soporterag.aplicacion.servicio.TagServicio;
import com.bsg.soporterag.dominio.modelo.Tag;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

@Service
public class GestionarTagCasoUsoImpl implements GestionarTagCasoUso {

    private static final Logger log = LoggerFactory.getLogger(GestionarTagCasoUsoImpl.class);

    private final TagServicio tagServicio;
    private final RepositorioServicio repositorioServicio;
    private final TagDtoMapper mapper;

    public GestionarTagCasoUsoImpl(TagServicio tagServicio, RepositorioServicio repositorioServicio, TagDtoMapper mapper) {
        this.tagServicio = tagServicio;
        this.repositorioServicio = repositorioServicio;
        this.mapper = mapper;
    }

    @Override
    public Mono<TagResponseDto> crearTag(CrearTagRequestDto request) {
        if (!StringUtils.hasText(request.getTag())) {
            return Mono.error(new IllegalArgumentException("El nombre del tag no puede estar vacío"));
        }
        Tag tag = mapper.aDominio(request);
        return tagServicio.crearTag(tag).map(mapper::aResponse);
    }

    @Override
    public Mono<ActualizarTagResponseDto> actualizarTag(String nombreTag, ActualizarTagRequestDto request) {
        return tagServicio.obtenerTagPorNombre(nombreTag)
                .switchIfEmpty(Mono.error(new IllegalArgumentException("El tag " + nombreTag + " no existe.")))
                .flatMap(existente -> {
                    // Nota arquitectural: cambiar el nombre del tag es complejo porque es la llave de negocio
                    // y los repositorios lo guardan por valor.
                    // Si se cambia el nombre del tag, se tendría que cambiar en TODOS los repositorios asociados.
                    // Por ahora, implementaremos la actualización simple (descripción, habilitado).
                    // Si realmente se necesita cambiar el nombre, se debe hacer una actualización en cascada.
                    
                    if (StringUtils.hasText(request.getNuevoNombreTag()) && !nombreTag.equals(request.getNuevoNombreTag())) {
                        log.warn("Se ha solicitado cambiar el nombre del tag de '{}' a '{}'. Esta operación requiere actualización en cascada en repositorios, lo cual no está implementado actualmente.", nombreTag, request.getNuevoNombreTag());
                        return Mono.error(new UnsupportedOperationException("El cambio de nombre de un tag (llave de negocio) no está soportado."));
                    }

                    Tag tagActualizado = new Tag();
                    tagActualizado.setTag(nombreTag); // Mantenemos el mismo
                    tagActualizado.setDescripcionTag(request.getDescripcionTag() != null ? request.getDescripcionTag() : existente.getDescripcionTag());
                    tagActualizado.setHabilitado(request.getHabilitado() != null ? request.getHabilitado() : existente.isHabilitado());

                    return tagServicio.actualizarTag(nombreTag, tagActualizado)
                            .map(guardado -> new ActualizarTagResponseDto(nombreTag, mapper.aResponse(guardado)));
                });
    }

    @Override
    public Mono<Void> eliminarTag(String nombreTag) {
        log.info("Iniciando eliminación del tag: {}", nombreTag);
        // 1. Eliminar la referencia del tag en TODOS los repositorios
        return repositorioServicio.desasociarTagDeTodos(nombreTag)
                .doOnSuccess(count -> log.info("Tag {} desasociado de {} repositorios.", nombreTag, count))
                // 2. Eliminar el documento del tag
                .then(tagServicio.eliminarTag(nombreTag))
                .doOnSuccess(v -> log.info("Tag {} eliminado completamente del sistema.", nombreTag));
    }

    @Override
    public Flux<TagResponseDto> obtenerTodosTags() {
        return tagServicio.obtenerTodosLosTags().map(mapper::aResponse);
    }

    @Override
    public Mono<TagResponseDto> obtenerTagPorNombre(String nombreTag) {
        return tagServicio.obtenerTagPorNombre(nombreTag)
                .switchIfEmpty(Mono.error(new IllegalArgumentException("No se encontró el tag: " + nombreTag)))
                .map(mapper::aResponse);
    }

    @Override
    public Mono<Void> agregarUrlTool(String nombreTag, String urlTool, String contextoUrl) {
        // Valida que exista primero
        return tagServicio.obtenerTagPorNombre(nombreTag)
                .switchIfEmpty(Mono.error(new IllegalArgumentException("No se encontró el tag: " + nombreTag)))
                .then(tagServicio.agregarUrlTool(nombreTag, urlTool, contextoUrl));
    }

    @Override
    public Mono<Void> eliminarUrlTool(String nombreTag, String urlTool) {
         return tagServicio.obtenerTagPorNombre(nombreTag)
                .switchIfEmpty(Mono.error(new IllegalArgumentException("No se encontró el tag: " + nombreTag)))
                .then(tagServicio.eliminarUrlTool(nombreTag, urlTool));
    }
}
