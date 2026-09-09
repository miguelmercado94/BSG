package com.bsg.soporterag.infraestructura.adaptador.web.websocket;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import reactor.core.publisher.Mono;
import reactor.core.publisher.Sinks;

import java.util.concurrent.ConcurrentHashMap;

/**
 * Registro en memoria de canales WebSocket activos, con la regla:
 * "un único canal activo por usuario". Cuando un usuario activa un canal (una HU),
 * el canal previo del mismo usuario se cierra de forma cooperativa.
 *
 * Nota: es por instancia. En despliegue multi-réplica haría falta coordinación
 * distribuida (p. ej. Redis pub/sub); para local (una instancia) es suficiente.
 */
@Component
public class RegistroCanales {

    private static final Logger log = LoggerFactory.getLogger(RegistroCanales.class);

    /** Canal activo por usuario. */
    private final ConcurrentHashMap<String, Canal> canalesPorUsuario = new ConcurrentHashMap<>();

    /**
     * Señal de cierre de un canal. El handler completa este Mono para cerrar
     * cooperativamente la sesión WebSocket asociada.
     */
    public record Canal(String usuario, String codigoTarea, String sessionId, Sinks.Empty<Void> cierre) {
        public Mono<Void> alCerrar() {
            return cierre.asMono();
        }
        public void solicitarCierre() {
            cierre.tryEmitEmpty();
        }
    }

    /**
     * Registra un canal para el usuario. Si ya existía otro canal activo del mismo usuario
     * (otra HU o la misma en otra pestaña), lo cierra antes de registrar el nuevo.
     */
    public Canal activar(String usuario, String codigoTarea, String sessionId) {
        Canal nuevo = new Canal(usuario, codigoTarea, sessionId, Sinks.empty());
        Canal previo = canalesPorUsuario.put(usuario, nuevo);
        if (previo != null && !previo.sessionId().equals(sessionId)) {
            log.info("Cerrando canal previo usuario={} tareaPrevia={} por nueva activación tarea={}",
                    usuario, previo.codigoTarea(), codigoTarea);
            previo.solicitarCierre();
        }
        log.info("Canal activado usuario={} tarea={} session={}", usuario, codigoTarea, sessionId);
        return nuevo;
    }

    /** Elimina el canal si sigue siendo el registrado para ese usuario/sesión. */
    public void desactivar(Canal canal) {
        if (canal == null) {
            return;
        }
        canalesPorUsuario.remove(canal.usuario(), canal);
        log.info("Canal desactivado usuario={} tarea={} session={}",
                canal.usuario(), canal.codigoTarea(), canal.sessionId());
    }
}
