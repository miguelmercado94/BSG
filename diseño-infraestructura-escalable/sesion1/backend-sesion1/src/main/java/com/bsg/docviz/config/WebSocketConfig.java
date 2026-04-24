package com.bsg.docviz.config;

import com.bsg.docviz.presentation.controller.RagChatWebSocketHandler;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.socket.config.annotation.EnableWebSocket;
import org.springframework.web.socket.config.annotation.WebSocketConfigurer;
import org.springframework.web.socket.config.annotation.WebSocketHandlerRegistry;

@Configuration
@EnableWebSocket
public class WebSocketConfig implements WebSocketConfigurer {

    private final RagChatWebSocketHandler ragChatWebSocketHandler;

    public WebSocketConfig(RagChatWebSocketHandler ragChatWebSocketHandler) {
        this.ragChatWebSocketHandler = ragChatWebSocketHandler;
    }

    @Override
    public void registerWebSocketHandlers(WebSocketHandlerRegistry registry) {
        registry.addHandler(ragChatWebSocketHandler, "/ws/rag-chat")
                .setAllowedOriginPatterns(
                        "http://localhost:*",
                        "http://127.0.0.1:*",
                        "https://*.up.railway.app");
    }
}
