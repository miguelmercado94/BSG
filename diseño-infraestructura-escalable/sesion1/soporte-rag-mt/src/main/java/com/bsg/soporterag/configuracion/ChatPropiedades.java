package com.bsg.soporterag.configuracion;

import org.springframework.boot.context.properties.ConfigurationProperties;
import java.util.Map;

@ConfigurationProperties(prefix = "soporte-rag.chat")
public record ChatPropiedades(
    Map<String, String> models
) {}
