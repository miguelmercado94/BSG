package com.bsg.soporterag.configuracion;

import org.springframework.context.annotation.Condition;
import org.springframework.context.annotation.ConditionContext;
import org.springframework.core.type.AnnotatedTypeMetadata;

/**
 * S3 habilitado cuando {@code soporte-rag.almacenamiento.s3.enabled=true}.
 */
public class CondicionS3Habilitado implements Condition {

    @Override
    public boolean matches(ConditionContext context, AnnotatedTypeMetadata metadata) {
        return context.getEnvironment()
                .getProperty("soporte-rag.almacenamiento.s3.enabled", Boolean.class, false);
    }
}
