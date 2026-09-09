package com.bsg.soporterag.configuracion;

import com.bsg.soporterag.infraestructura.adaptador.web.websocket.ChatWebSocketHandler;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.Ordered;
import org.springframework.web.reactive.HandlerMapping;
import org.springframework.web.reactive.handler.SimpleUrlHandlerMapping;
import org.springframework.web.reactive.socket.server.support.WebSocketHandlerAdapter;

import java.util.Map;

/**
 * Configuración WebSocket (WebFlux). Mapea la ruta del chat por HU al handler.
 * La ruta usa patrón con {codigoTarea}; el handler extrae la HU del path.
 */
@Configuration
public class WebSocketConfiguracion {

    /** Ruta del canal de chat por HU. Debe coincidir con el prefijo que enruta el gateway (/docviz/ws/**). */
    private static final String RUTA_CHAT = "/ws/chat/**";

    @Bean
    public HandlerMapping webSocketHandlerMapping(ChatWebSocketHandler chatWebSocketHandler) {
        SimpleUrlHandlerMapping mapping = new SimpleUrlHandlerMapping();
        mapping.setUrlMap(Map.of(RUTA_CHAT, chatWebSocketHandler));
        // Prioridad alta para que resuelva antes que los controladores REST anotados.
        mapping.setOrder(Ordered.HIGHEST_PRECEDENCE);
        return mapping;
    }

    @Bean
    public WebSocketHandlerAdapter webSocketHandlerAdapter() {
        return new WebSocketHandlerAdapter();
    }
}
