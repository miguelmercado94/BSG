package com.bsg.soporterag.dominio.puerto.salida;

import com.bsg.soporterag.dominio.modelo.MensajeChat;
import com.bsg.soporterag.dominio.modelo.Tarea;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

public interface TareaRepositorioPort {

    Mono<Tarea> guardar(Tarea tarea);

    Mono<Tarea> buscarPorId(String id);

    Mono<Tarea> buscarPorCodigo(String codigoTarea);

    Flux<Tarea> buscarPorUrlRepo(String urlRepo);

    Flux<Tarea> buscarPorCodigoUsuario(String codigoUsuario);

    Mono<Void> eliminar(String id);

    Mono<Void> agregarMensajeChat(String codigoTarea, MensajeChat mensaje);

    Mono<Tarea> actualizarResumen(String codigoTarea, String resumen);
}
