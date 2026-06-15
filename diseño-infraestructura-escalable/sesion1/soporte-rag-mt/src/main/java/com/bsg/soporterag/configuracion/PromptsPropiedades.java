package com.bsg.soporterag.configuracion;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "soporte-rag.prompt")
public record PromptsPropiedades(
    String sistema,
    String usuario,
    String analisis
) {}
