package com.bsg.docviz.config;

import org.springframework.context.annotation.Condition;
import org.springframework.context.annotation.ConditionContext;
import org.springframework.core.type.AnnotatedTypeMetadata;

import java.nio.file.Files;
import java.nio.file.Path;

/**
 * Activa beans de Firebase solo si está habilitado y hay un fichero de credenciales resolvible.
 * Evita fallar al arrancar con {@code docviz.firebase.enabled=true} pero sin JSON configurado.
 */
public class FirebaseOnCredentialsPresentCondition implements Condition {

    @Override
    public boolean matches(ConditionContext context, AnnotatedTypeMetadata metadata) {
        var env = context.getEnvironment();
        if (!Boolean.parseBoolean(env.getProperty("docviz.firebase.enabled", "false"))) {
            return false;
        }
        String credPath = env.getProperty("docviz.firebase.credentials-path", "");
        if (credPath == null || credPath.isBlank()) {
            String gac = System.getenv("GOOGLE_APPLICATION_CREDENTIALS");
            credPath = gac != null ? gac.trim() : "";
        }
        if (credPath.isBlank()) {
            return false;
        }
        return Files.isRegularFile(Path.of(credPath));
    }
}
