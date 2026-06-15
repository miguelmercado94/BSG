package com.bsg.soporterag.aplicacion.servicio.impl;

import com.bsg.soporterag.aplicacion.servicio.CelulaServicio;
import com.bsg.soporterag.aplicacion.servicio.RepositorioServicio;
import com.bsg.soporterag.dominio.modelo.Repositorio;
import com.bsg.soporterag.dominio.puerto.salida.RepositorioRepositorioPort;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

@Service
public class RepositorioServicioImpl implements RepositorioServicio {

    private final RepositorioRepositorioPort repositorioPort;
    private final CelulaServicio celulaServicio;

    public RepositorioServicioImpl(
            RepositorioRepositorioPort repositorioPort,
            CelulaServicio celulaServicio) {
        this.repositorioPort = repositorioPort;
        this.celulaServicio = celulaServicio;
    }

    @Override
    public Mono<Repositorio> crearNuevoRepo(Repositorio repositorio) {
        return repositorioPort.guardar(repositorio);
    }

    @Override
    public Mono<Repositorio> actualizarRepo(Repositorio repositorio, String urlClaveOriginal) {
        Mono<Repositorio> preparado = Mono.just(repositorio);
        String urlActual = repositorio.getUrl();
        if (StringUtils.hasText(urlActual) && !urlActual.equals(urlClaveOriginal)) {
            preparado = repositorioPort.existePorUrl(urlActual)
                    .flatMap(existe -> Boolean.TRUE.equals(existe)
                            ? Mono.error(new IllegalArgumentException(
                                    "Ya existe un repositorio con la URL: " + urlActual))
                            : Mono.just(repositorio));
        }
        return preparado.flatMap(repositorioPort::guardar);
    }

    @Override
    public Mono<Void> eliminarRepo(String url) {
        return obtenerRepo(url).flatMap(repositorioPort::eliminar);
    }

    @Override
    public Mono<Repositorio> obtenerRepo(String url) {
        return repositorioPort.buscarPorUrl(normalizarUrl(url))
                .switchIfEmpty(Mono.error(new IllegalArgumentException(
                        "Repositorio no encontrado para la URL: " + url)));
    }

    @Override
    public Mono<Repositorio> obtenerRepoPorNombre(String nombre) {
        if (!StringUtils.hasText(nombre)) {
            return Mono.error(new IllegalArgumentException("El nombre del repositorio es obligatorio"));
        }
        return repositorioPort.buscarPorNombre(nombre.trim())
                .switchIfEmpty(Mono.error(new IllegalArgumentException(
                        "Repositorio no encontrado para el nombre: " + nombre)));
    }

    @Override
    public Flux<Repositorio> obtenerTodosPorCelula(String codigoCelula) {
        return celulaServicio.listarNombresRepoPorCodigoCelula(codigoCelula)
                .flatMap(nombreRepo -> repositorioPort.buscarPorNombre(nombreRepo)
                        .switchIfEmpty(Mono.error(new IllegalStateException(
                                "Repositorio global no encontrado para nombre_repo='" + nombreRepo
                                        + "' (célula " + codigoCelula + ")"))));
    }

    @Override
    public Flux<Repositorio> obtenerTodosPorTag(String nombreTag) {
        return repositorioPort.buscarPorTag(nombreTag);
    }

    @Override
    public Mono<Long> desasociarTagDeTodos(String nombreTag) {
        return repositorioPort.desasociarTagDeTodos(nombreTag);
    }

    private String normalizarUrl(String url) {
        if (!StringUtils.hasText(url)) {
            throw new IllegalArgumentException("La URL del repositorio es obligatoria");
        }
        return url.trim();
    }
}
