package com.bsg.soporterag.aplicacion.servicio.impl;

import com.bsg.soporterag.aplicacion.servicio.TareaServicio;
import com.bsg.soporterag.dominio.modelo.MensajeChat;
import com.bsg.soporterag.dominio.modelo.Tarea;
import com.bsg.soporterag.dominio.puerto.salida.HistorialChatCachePort;
import com.bsg.soporterag.dominio.puerto.salida.TareaRepositorioPort;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

@Service
public class TareaServicioImpl implements TareaServicio {

    private final TareaRepositorioPort tareaRepositorioPort;
    private final HistorialChatCachePort historialChatCachePort;

    public TareaServicioImpl(
            TareaRepositorioPort tareaRepositorioPort,
            HistorialChatCachePort historialChatCachePort) {
        this.tareaRepositorioPort = tareaRepositorioPort;
        this.historialChatCachePort = historialChatCachePort;
    }

    @Override
    public Mono<Tarea> crearTarea(Tarea tarea) {
        return tareaRepositorioPort.guardar(tarea);
    }

    @Override
    public Mono<Tarea> actualizarTarea(String codigoTarea, Tarea tareaActualizada) {
        return tareaRepositorioPort.buscarPorCodigo(codigoTarea)
                .flatMap(existente -> {
                    // Preservar el ID y el código de tarea original
                    tareaActualizada.setId(existente.getId());
                    tareaActualizada.setCodigoTarea(existente.getCodigoTarea());
                    return tareaRepositorioPort.guardar(tareaActualizada);
                })
                .switchIfEmpty(Mono.error(new IllegalArgumentException("No se encontró la tarea con código: " + codigoTarea)));
    }

    @Override
    public Mono<Void> eliminarTarea(String codigoTarea) {
        return tareaRepositorioPort.buscarPorCodigo(codigoTarea)
                .flatMap(tarea -> tareaRepositorioPort.eliminar(tarea.getId()))
                .then(historialChatCachePort.invalidar(codigoTarea));
    }

    @Override
    public Mono<Tarea> obtenerPorCodigo(String codigoTarea) {
        return tareaRepositorioPort.buscarPorCodigo(codigoTarea);
    }

    @Override
    public Flux<Tarea> obtenerTareasPorUsuario(String codigoUsuario) {
        return tareaRepositorioPort.buscarPorCodigoUsuario(codigoUsuario);
    }

    @Override
    public Mono<Void> agregarMensajeChat(String codigoTarea, MensajeChat mensaje) {
        return tareaRepositorioPort.agregarMensajeChat(codigoTarea, mensaje);
    }
}
