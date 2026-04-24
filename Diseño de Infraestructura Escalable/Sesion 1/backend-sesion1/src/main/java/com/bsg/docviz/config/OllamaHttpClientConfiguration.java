package com.bsg.docviz.config;

import org.springframework.boot.web.client.ClientHttpRequestFactories;
import org.springframework.boot.web.client.ClientHttpRequestFactorySettings;
import org.springframework.boot.web.client.RestClientCustomizer;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.time.Duration;

/**
 * Evita que las llamadas HTTP a Ollama (embeddings/chat) queden sin límite de espera si el daemon no responde.
 * La primera carga del modelo de embedding puede tardar varios minutos; el read timeout es amplio a propósito.
 */
@Configuration
public class OllamaHttpClientConfiguration {

    @Bean
    public RestClientCustomizer ollamaRestTimeouts() {
        return restClientBuilder -> {
            ClientHttpRequestFactorySettings settings = ClientHttpRequestFactorySettings.DEFAULTS
                    .withConnectTimeout(Duration.ofSeconds(30))
                    .withReadTimeout(Duration.ofMinutes(20));
            restClientBuilder.requestFactory(ClientHttpRequestFactories.get(settings));
        };
    }
}
