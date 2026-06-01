package com.bsg.soporterag.configuracion;

import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.ComponentScan;

/**
 * Registro explícito de capas (opcional; {@link com.bsg.soporterag.SoporteRagMtApplication} ya escanea {@code com.bsg.soporterag}).
 */
@Configuration
@ComponentScan(basePackages = {
        "com.bsg.soporterag.configuracion",
        "com.bsg.soporterag.aplicacion",
        "com.bsg.soporterag.infraestructura"
})
public class ArquitecturaLimpiaConfiguracion {
}
