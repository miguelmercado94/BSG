package com.bsg.soporterag.aplicacion.casodeuso.impl;

import com.bsg.soporterag.aplicacion.casodeuso.GestionarRepositorioCasoUso;
import com.bsg.soporterag.aplicacion.casodeuso.GestionarTareaCasoUso;
import com.bsg.soporterag.aplicacion.dto.request.ActualizarEstadoTareaRequestDto;
import com.bsg.soporterag.aplicacion.dto.request.ActualizarRepositorioRequestDto;
import com.bsg.soporterag.aplicacion.dto.request.ActualizarTareaRequestDto;
import com.bsg.soporterag.aplicacion.dto.request.CrearTareaRequestDto;
import com.bsg.soporterag.aplicacion.dto.response.TareaResponseDto;
import com.bsg.soporterag.aplicacion.mapperdto.TareaDtoMapper;
import com.bsg.soporterag.aplicacion.servicio.CelulaServicio;
import com.bsg.soporterag.aplicacion.servicio.RepositorioServicio;
import com.bsg.soporterag.aplicacion.servicio.TareaServicio;
import com.bsg.soporterag.dominio.excepcion.CelulaNoEncontradaException;
import com.bsg.soporterag.dominio.modelo.EstadoTarea;
import com.bsg.soporterag.dominio.modelo.Tarea;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

@Service
public class GestionarTareaCasoUsoImpl implements GestionarTareaCasoUso {

    private static final Logger log = LoggerFactory.getLogger(GestionarTareaCasoUsoImpl.class);

    private final TareaServicio tareaServicio;
    private final RepositorioServicio repositorioServicio;
    private final CelulaServicio celulaServicio;
    private final GestionarRepositorioCasoUso gestionarRepositorioCasoUso;
    private final TareaDtoMapper mapper;

    public GestionarTareaCasoUsoImpl(
            TareaServicio tareaServicio,
            RepositorioServicio repositorioServicio,
            CelulaServicio celulaServicio,
            GestionarRepositorioCasoUso gestionarRepositorioCasoUso,
            TareaDtoMapper mapper) {
        this.tareaServicio = tareaServicio;
        this.repositorioServicio = repositorioServicio;
        this.celulaServicio = celulaServicio;
        this.gestionarRepositorioCasoUso = gestionarRepositorioCasoUso;
        this.mapper = mapper;
    }

    @Override
    public Mono<TareaResponseDto> crearTarea(CrearTareaRequestDto request) {
        // Validar repositorio
        Mono<Void> validarRepo = repositorioServicio.obtenerRepo(request.getUrlRepo()).then();
        
        // Validar célula
        Mono<Void> validarCelula = celulaServicio.obtenerPorCodigo(request.getCodigoCelula())
                .switchIfEmpty(Mono.error(new CelulaNoEncontradaException(request.getCodigoCelula())))
                .then();

        // Validar asociación Repositorio-Célula
        Mono<Void> validarAsociacion = repositorioServicio.obtenerRepo(request.getUrlRepo())
                .flatMap(repo -> celulaServicio.existeAsociacion(request.getCodigoCelula(), repo.getNombre()))
                .flatMap(existe -> existe 
                        ? Mono.<Void>empty() 
                        : Mono.error(new IllegalArgumentException("El repositorio no está asociado a la célula indicada")));

        return Mono.when(validarRepo, validarCelula)
                .then(validarAsociacion)
                .then(Mono.defer(() -> {
                    Tarea nuevaTarea = mapper.aDominio(request);
                    return tareaServicio.crearTarea(nuevaTarea);
                }))
                .map(mapper::aResponse);
    }

    @Override
    public Mono<TareaResponseDto> actualizarTarea(String codigoTarea, ActualizarTareaRequestDto request) {
        return tareaServicio.obtenerPorCodigo(codigoTarea)
                .switchIfEmpty(Mono.error(new IllegalArgumentException("No se encontró la tarea con código: " + codigoTarea)))
                .flatMap(existente -> {
                    if (existente.getEstadoTarea() != EstadoTarea.BORRADOR) {
                        return Mono.error(new IllegalStateException("Solo se pueden actualizar tareas en estado BORRADOR"));
                    }

                    if (StringUtils.hasText(request.getTitulo())) {
                        existente.setTitulo(request.getTitulo());
                    }
                    if (StringUtils.hasText(request.getEnunciadoPrincipal())) {
                        existente.setEnunciadoPrincipal(request.getEnunciadoPrincipal());
                    }

                    if (StringUtils.hasText(request.getUrlRepo()) && !request.getUrlRepo().equals(existente.getUrlRepo())) {
                        // Si cambia el repo, validar de nuevo
                        return repositorioServicio.obtenerRepo(request.getUrlRepo())
                                .flatMap(repo -> celulaServicio.existeAsociacion(existente.getCodigoCelula(), repo.getNombre()))
                                .flatMap(existe -> {
                                    if (!existe) return Mono.error(new IllegalArgumentException("El nuevo repositorio no está asociado a la célula de la tarea"));
                                    existente.setUrlRepo(request.getUrlRepo());
                                    return tareaServicio.actualizarTarea(codigoTarea, existente);
                                });
                    }

                    return tareaServicio.actualizarTarea(codigoTarea, existente);
                })
                .map(mapper::aResponse);
    }

    @Override
    public Mono<Void> eliminarTarea(String codigoTarea) {
        return tareaServicio.eliminarTarea(codigoTarea);
    }

    @Override
    public Flux<TareaResponseDto> obtenerTareasPorUsuario(String codigoUsuario) {
        return tareaServicio.obtenerTareasPorUsuario(codigoUsuario)
                .map(mapper::aResponse);
    }

    @Override
    public Mono<TareaResponseDto> actualizarEstado(String codigoTarea, ActualizarEstadoTareaRequestDto request) {
         return tareaServicio.obtenerPorCodigo(codigoTarea)
                .switchIfEmpty(Mono.error(new IllegalArgumentException("No se encontró la tarea con código: " + codigoTarea)))
                .flatMap(existente -> {
                    EstadoTarea estadoActual = existente.getEstadoTarea();
                    EstadoTarea nuevoEstado = request.getNuevoEstado();

                    if (estadoActual == EstadoTarea.TERMINADA) {
                        return Mono.error(new IllegalStateException("Una tarea TERMINADA no puede cambiar de estado"));
                    }

                    if (estadoActual == EstadoTarea.CANCELADA && nuevoEstado != EstadoTarea.INICIADA) {
                        return Mono.error(new IllegalStateException("Una tarea CANCELADA solo puede pasar a estado INICIADA"));
                    }

                    existente.setEstadoTarea(nuevoEstado);

                    Mono<Tarea> guardarTareaMono = tareaServicio.actualizarTarea(codigoTarea, existente);

                    if (nuevoEstado == EstadoTarea.INICIADA && estadoActual != EstadoTarea.INICIADA) {
                        // Sincronizar repositorio
                        ActualizarRepositorioRequestDto updateRepoReq = new ActualizarRepositorioRequestDto();
                        updateRepoReq.setUrl(existente.getUrlRepo());
                        return gestionarRepositorioCasoUso.actualizarRepo(updateRepoReq)
                                .then(guardarTareaMono);
                    }

                    return guardarTareaMono;
                })
                .map(mapper::aResponse);
    }
}
