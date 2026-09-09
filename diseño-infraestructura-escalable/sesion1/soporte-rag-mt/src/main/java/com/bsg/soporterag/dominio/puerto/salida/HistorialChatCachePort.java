package com.bsg.soporterag.dominio.puerto.salida;

import com.bsg.soporterag.dominio.modelo.MensajeChat;
import reactor.core.publisher.Mono;

import java.util.List;

/**
 * Cache del historial de chat por HU (código de tarea).
 * Permite servir el historial al LLM sin golpear MongoDB en cada turno.
 *
 * Implementación write-through: cuando llega un mensaje nuevo se persiste en la BD
 * y luego se refresca esta cache con el historial completo de la tarea.
 */
public interface HistorialChatCachePort {

    /**
     * Devuelve el historial cacheado de la tarea. Si no hay entrada en cache
     * (o la cache está deshabilitada), devuelve {@link Mono#empty()} para que el
     * caller haga fallback a la base de datos.
     */
    Mono<List<MensajeChat>> obtenerHistorial(String codigoTarea);

    /** Sustituye en cache el historial completo de la tarea (write-through). */
    Mono<Void> guardarHistorial(String codigoTarea, List<MensajeChat> mensajes);

    /** Elimina el historial cacheado de la tarea (p. ej. al borrar la tarea). */
    Mono<Void> invalidar(String codigoTarea);
}
