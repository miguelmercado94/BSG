package com.bsg.soporterag.aplicacion.servicio;

import com.bsg.soporterag.dominio.modelo.MensajeChat;
import com.bsg.soporterag.dominio.modelo.Tarea;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

public interface TareaServicio {

    Mono<Tarea> crearTarea(Tarea tarea);

    Mono<Tarea> actualizarTarea(String codigoTarea, Tarea tarea);

    Mono<Void> eliminarTarea(String codigoTarea);

    Mono<Tarea> obtenerPorCodigo(String codigoTarea);

    Flux<Tarea> obtenerTareasPorUsuario(String codigoUsuario);

    Mono<Void> agregarMensajeChat(String codigoTarea, MensajeChat mensaje);
}
