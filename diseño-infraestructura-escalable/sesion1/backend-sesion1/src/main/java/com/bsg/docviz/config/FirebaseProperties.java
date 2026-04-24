package com.bsg.docviz.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * Firestore vía Firebase Admin SDK. Requiere JSON de cuenta de servicio (consola Firebase → Configuración del proyecto → Cuentas de servicio).
 */
@ConfigurationProperties(prefix = "docviz.firebase")
public class FirebaseProperties {

    /**
     * Si es false, no se inicializa Firebase (arranque sin credenciales).
     */
    private boolean enabled = false;

    private String projectId = "sesion-bsg";

    /**
     * Ruta al JSON de la cuenta de servicio. Si está vacío, se usa la variable de entorno {@code GOOGLE_APPLICATION_CREDENTIALS}.
     */
    private String credentialsPath = "";

    public boolean isEnabled() {
        return enabled;
    }

    public void setEnabled(boolean enabled) {
        this.enabled = enabled;
    }

    public String getProjectId() {
        return projectId;
    }

    public void setProjectId(String projectId) {
        this.projectId = projectId != null ? projectId.trim() : "";
    }

    public String getCredentialsPath() {
        return credentialsPath;
    }

    public void setCredentialsPath(String credentialsPath) {
        this.credentialsPath = credentialsPath != null ? credentialsPath.trim() : "";
    }
}
