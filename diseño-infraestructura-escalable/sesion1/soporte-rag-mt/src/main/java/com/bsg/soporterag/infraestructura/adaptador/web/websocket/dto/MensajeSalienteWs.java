package com.bsg.soporterag.infraestructura.adaptador.web.websocket.dto;

import com.fasterxml.jackson.annotation.JsonInclude;

/**
 * Mensaje que el servidor envía al cliente por el WebSocket. El campo {@code tipo}
 * indica la naturaleza del evento:
 * <ul>
 *   <li>CANAL_ACTIVADO — confirmación de apertura del canal para una HU.</li>
 *   <li>HISTORIAL — historial previo de la conversación (texto formateado).</li>
 *   <li>TOKEN — fragmento de la respuesta del LLM en streaming.</li>
 *   <li>FIN — la respuesta terminó.</li>
 *   <li>CANAL_CERRADO — el canal se cerró (p. ej. porque se abrió otro).</li>
 *   <li>ERROR — error procesando el mensaje.</li>
 * </ul>
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
public record MensajeSalienteWs(
        String tipo,
        String contenido,
        String codigoTarea,
        String motivo) {

    public static MensajeSalienteWs canalActivado(String codigoTarea) {
        return new MensajeSalienteWs("CANAL_ACTIVADO", null, codigoTarea, null);
    }

    public static MensajeSalienteWs historial(String contenido) {
        return new MensajeSalienteWs("HISTORIAL", contenido, null, null);
    }

    public static MensajeSalienteWs token(String contenido) {
        return new MensajeSalienteWs("TOKEN", contenido, null, null);
    }

    public static MensajeSalienteWs fin() {
        return new MensajeSalienteWs("FIN", null, null, null);
    }

    public static MensajeSalienteWs canalCerrado(String motivo) {
        return new MensajeSalienteWs("CANAL_CERRADO", null, null, motivo);
    }

    public static MensajeSalienteWs error(String mensaje) {
        return new MensajeSalienteWs("ERROR", null, null, mensaje);
    }
}
