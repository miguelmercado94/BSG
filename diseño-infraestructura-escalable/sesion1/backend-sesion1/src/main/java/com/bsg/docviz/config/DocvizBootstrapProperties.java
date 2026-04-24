package com.bsg.docviz.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * Arranque opcional desde {@link com.bsg.docviz.DocumentContextVisualizerApplication}: clona un repo HTTPS público
 * y opcionalmente ejecuta la ingesta vectorial (mismo flujo que {@code POST /connect/git} + {@code POST /vector/ingest}).
 */
@ConfigurationProperties(prefix = "docviz.bootstrap")
public class DocvizBootstrapProperties {

    /**
     * Si es true y {@link #gitUrl} no está vacío, se ejecuta al arrancar (perfil distinto de {@code test}).
     */
    private boolean enabled = false;

    /**
     * URL {@code https://...} del repositorio (p. ej. GitHub público).
     */
    private String gitUrl = "";

    /**
     * Coincide con {@code X-DocViz-User}: namespace de sesión y de vectores.
     */
    private String userId = "bootstrap";

    /**
     * Tras el clone, ejecutar {@link com.bsg.docviz.vector.VectorIngestService#ingestAll()}.
     */
    private boolean runIngest = true;

    public boolean isEnabled() {
        return enabled;
    }

    public void setEnabled(boolean enabled) {
        this.enabled = enabled;
    }

    public String getGitUrl() {
        return gitUrl;
    }

    public void setGitUrl(String gitUrl) {
        this.gitUrl = gitUrl != null ? gitUrl.trim() : "";
    }

    public String getUserId() {
        return userId;
    }

    public void setUserId(String userId) {
        this.userId = userId != null ? userId.trim() : "bootstrap";
    }

    public boolean isRunIngest() {
        return runIngest;
    }

    public void setRunIngest(boolean runIngest) {
        this.runIngest = runIngest;
    }
}
