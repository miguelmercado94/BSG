package com.bsg.soporterag.infraestructura.adaptador.web.websocket;

import com.bsg.soporterag.aplicacion.casodeuso.InteractuarChatCasoUso;
import com.bsg.soporterag.aplicacion.dto.request.ChatRequestDto;
import com.bsg.soporterag.infraestructura.adaptador.web.websocket.dto.MensajeEntranteWs;
import com.bsg.soporterag.infraestructura.adaptador.web.websocket.dto.MensajeSalienteWs;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.socket.WebSocketHandler;
import org.springframework.web.reactive.socket.WebSocketMessage;
import org.springframework.web.reactive.socket.WebSocketSession;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.net.URI;
import java.util.List;

/**
 * Handler WebSocket del chat por HU (canal). Un usuario tiene un canal por HU y solo uno
 * activo a la vez: al abrir el canal de una HU se cierra el canal previo del mismo usuario.
 *
 * URL: /ws/chat/{codigoTarea}. El usuario llega en el header X-User-Id (inyectado por el
 * gateway tras validar el JWT); como fallback local se acepta el query param ?usuario=.
 *
 * Protocolo (JSON):
 *   entrada:  {"tipo":"MENSAJE","contenido":"..."}
 *   salida:   {"tipo":"CANAL_ACTIVADO","codigoTarea":"HU002"}
 *             {"tipo":"HISTORIAL","contenido":"..."}
 *             {"tipo":"TOKEN","contenido":"..."}  (varios)
 *             {"tipo":"FIN"}
 *             {"tipo":"CANAL_CERRADO","motivo":"..."}
 *             {"tipo":"ERROR","motivo":"..."}
 */
@Component
public class ChatWebSocketHandler implements WebSocketHandler {

    private static final Logger log = LoggerFactory.getLogger(ChatWebSocketHandler.class);

    private final InteractuarChatCasoUso interactuarChatCasoUso;
    private final RegistroCanales registroCanales;
    private final ObjectMapper objectMapper;

    public ChatWebSocketHandler(
            InteractuarChatCasoUso interactuarChatCasoUso,
            RegistroCanales registroCanales,
            ObjectMapper objectMapper) {
        this.interactuarChatCasoUso = interactuarChatCasoUso;
        this.registroCanales = registroCanales;
        this.objectMapper = objectMapper;
    }

    @Override
    public Mono<Void> handle(WebSocketSession session) {
        String codigoTarea = extraerCodigoTarea(session);
        String usuario = extraerUsuario(session);

        if (codigoTarea == null || codigoTarea.isBlank() || usuario == null || usuario.isBlank()) {
            return session.send(Mono.just(session.textMessage(
                    serializar(MensajeSalienteWs.error("Falta codigoTarea o usuario"))))).then(session.close());
        }

        // Activar el canal (cierra el canal previo del mismo usuario).
        RegistroCanales.Canal canal = registroCanales.activar(usuario, codigoTarea, session.getId());

        // Mensaje de apertura + historial previo de la HU.
        Mono<MensajeSalienteWs> historialMono = interactuarChatCasoUso.obtenerHistorialFormateado(codigoTarea)
                .map(MensajeSalienteWs::historial)
                .defaultIfEmpty(MensajeSalienteWs.historial(""));

        Flux<MensajeSalienteWs> apertura = Flux.concat(
                Mono.just(MensajeSalienteWs.canalActivado(codigoTarea)),
                historialMono);

        // Por cada mensaje entrante del cliente, se genera un stream de respuesta (TOKEN* + FIN).
        Flux<MensajeSalienteWs> respuestas = session.receive()
                .map(WebSocketMessage::getPayloadAsText)
                .concatMap(payload -> procesarEntrada(codigoTarea, payload));

        Flux<MensajeSalienteWs> saliente = Flux.concat(apertura, respuestas);

        Mono<Void> envio = session.send(saliente.map(m -> session.textMessage(serializar(m))));

        // La sesión se cierra si el cliente cierra, o si otro canal del mismo usuario fuerza el cierre.
        Mono<Void> cierreForzado = canal.alCerrar()
                .then(session.send(Mono.just(session.textMessage(
                        serializar(MensajeSalienteWs.canalCerrado("Se activó otro canal"))))))
                .then(session.close());

        return Flux.merge(envio, cierreForzado)
                .then()
                .doFinally(sig -> registroCanales.desactivar(canal));
    }

    private Flux<MensajeSalienteWs> procesarEntrada(String codigoTarea, String payload) {
        MensajeEntranteWs entrada = deserializar(payload);
        if (entrada == null || !entrada.esMensaje() || entrada.contenido() == null || entrada.contenido().isBlank()) {
            return Flux.just(MensajeSalienteWs.error("Mensaje vacío o formato inválido"));
        }
        ChatRequestDto request = new ChatRequestDto();
        request.setMensaje(entrada.contenido());

        return interactuarChatCasoUso.conversarStream(codigoTarea, request)
                .map(MensajeSalienteWs::token)
                .concatWith(Mono.just(MensajeSalienteWs.fin()))
                .onErrorResume(e -> {
                    log.error("Error en conversarStream WS tarea={}: {}", codigoTarea, e.getMessage());
                    return Flux.just(MensajeSalienteWs.error(e.getMessage()));
                });
    }

    private String extraerCodigoTarea(WebSocketSession session) {
        URI uri = session.getHandshakeInfo().getUri();
        String path = uri.getPath(); // .../ws/chat/{codigoTarea}
        int idx = path.indexOf("/ws/chat/");
        if (idx < 0) {
            return null;
        }
        String resto = path.substring(idx + "/ws/chat/".length());
        int slash = resto.indexOf('/');
        return slash >= 0 ? resto.substring(0, slash) : resto;
    }

    private String extraerUsuario(WebSocketSession session) {
        List<String> userId = session.getHandshakeInfo().getHeaders().get("X-User-Id");
        if (userId != null && !userId.isEmpty() && userId.get(0) != null && !userId.get(0).isBlank()) {
            return userId.get(0);
        }
        // Fallback local (sin gateway): ?usuario=
        String query = session.getHandshakeInfo().getUri().getQuery();
        if (query != null) {
            for (String par : query.split("&")) {
                String[] kv = par.split("=", 2);
                if (kv.length == 2 && "usuario".equals(kv[0])) {
                    return kv[1];
                }
            }
        }
        return null;
    }

    private String serializar(MensajeSalienteWs mensaje) {
        try {
            return objectMapper.writeValueAsString(mensaje);
        } catch (Exception e) {
            return "{\"tipo\":\"ERROR\",\"motivo\":\"serializacion\"}";
        }
    }

    private MensajeEntranteWs deserializar(String payload) {
        try {
            return objectMapper.readValue(payload, MensajeEntranteWs.class);
        } catch (Exception e) {
            return null;
        }
    }
}
