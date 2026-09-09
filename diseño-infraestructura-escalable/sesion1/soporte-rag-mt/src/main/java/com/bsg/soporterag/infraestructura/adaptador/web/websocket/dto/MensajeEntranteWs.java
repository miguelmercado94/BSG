package com.bsg.soporterag.infraestructura.adaptador.web.websocket.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

/**
 * Mensaje que envía el cliente por el WebSocket.
 * Ejemplo: {"tipo":"MENSAJE","contenido":"¿Qué dependencias usa el proyecto?"}
 */
@JsonIgnoreProperties(ignoreUnknown = true)
public record MensajeEntranteWs(String tipo, String contenido) {
    public boolean esMensaje() {
        return tipo == null || "MENSAJE".equalsIgnoreCase(tipo);
    }
}
