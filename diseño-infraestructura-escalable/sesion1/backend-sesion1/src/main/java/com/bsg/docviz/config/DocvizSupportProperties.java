package com.bsg.docviz.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * Almacenamiento de Markdown de soporte en S3 (p. ej. LocalStack) + embeddings en el mismo namespace pgvector que el repo.
 */
@ConfigurationProperties(prefix = "docviz.support")
public class DocvizSupportProperties {

    private boolean enabled = false;
    private String s3Endpoint = "";
    /**
     * Host base solo para URLs presignadas devueltas al navegador. Vacío = mismo que {@link #s3Endpoint}.
     * En Docker el cliente S3 suele usar {@code http://localstack:4566}; el navegador no resuelve {@code localstack},
     * así que aquí p. ej. {@code http://127.0.0.1:4566} (puerto publicado en el host).
     */
    private String s3PresignEndpoint = "";
    private String s3Region = "us-east-1";
    private String s3Bucket = "soporte";
    private String accessKey = "test";
    private String secretKey = "test";
    /** Tamaño máximo del archivo subido (bytes). */
    private long maxUploadBytes = 2_000_000L;

    /**
     * Prefijo por repo dentro del bucket {@code soporte}: clave {@code {repoSlug}/{archivo}.{ext}}.
     */
    private String supportRepoPrefixTemplate = "{repoSlug}/";

    /** Prefijo para subidas de sesión sin repo de célula. */
    private String supportSessionPrefixTemplate = "_session/";

    /** Validez de URLs presignadas GET devueltas al front (listados). */
    private long presignedUrlTtlSeconds = 3600L;

    public boolean isEnabled() {
        return enabled;
    }

    public void setEnabled(boolean enabled) {
        this.enabled = enabled;
    }

    public String getS3Endpoint() {
        return s3Endpoint;
    }

    public void setS3Endpoint(String s3Endpoint) {
        this.s3Endpoint = s3Endpoint != null ? s3Endpoint.trim() : "";
    }

    public String getS3PresignEndpoint() {
        return s3PresignEndpoint;
    }

    public void setS3PresignEndpoint(String s3PresignEndpoint) {
        this.s3PresignEndpoint = s3PresignEndpoint != null ? s3PresignEndpoint.trim() : "";
    }

    /** Endpoint efectivo para firmar GET que consumirá el front (navegador). */
    public String effectiveS3PresignEndpoint() {
        return !s3PresignEndpoint.isBlank() ? s3PresignEndpoint : s3Endpoint;
    }

    public String getS3Region() {
        return s3Region;
    }

    public void setS3Region(String s3Region) {
        this.s3Region = s3Region != null ? s3Region.trim() : "us-east-1";
    }

    public String getS3Bucket() {
        return s3Bucket;
    }

    public void setS3Bucket(String s3Bucket) {
        this.s3Bucket = s3Bucket != null ? s3Bucket.trim() : "soporte";
    }

    public String getAccessKey() {
        return accessKey;
    }

    public void setAccessKey(String accessKey) {
        this.accessKey = accessKey != null ? accessKey : "";
    }

    public String getSecretKey() {
        return secretKey;
    }

    public void setSecretKey(String secretKey) {
        this.secretKey = secretKey != null ? secretKey : "";
    }

    public long getMaxUploadBytes() {
        return maxUploadBytes;
    }

    public void setMaxUploadBytes(long maxUploadBytes) {
        this.maxUploadBytes = maxUploadBytes > 0 ? maxUploadBytes : 2_000_000L;
    }

    public String getSupportRepoPrefixTemplate() {
        return supportRepoPrefixTemplate;
    }

    public void setSupportRepoPrefixTemplate(String supportRepoPrefixTemplate) {
        this.supportRepoPrefixTemplate =
                supportRepoPrefixTemplate != null && !supportRepoPrefixTemplate.isBlank()
                        ? supportRepoPrefixTemplate.trim()
                        : "{repoSlug}/";
    }

    public String getSupportSessionPrefixTemplate() {
        return supportSessionPrefixTemplate;
    }

    public void setSupportSessionPrefixTemplate(String supportSessionPrefixTemplate) {
        this.supportSessionPrefixTemplate =
                supportSessionPrefixTemplate != null && !supportSessionPrefixTemplate.isBlank()
                        ? supportSessionPrefixTemplate.trim()
                        : "_session/";
    }

    public long getPresignedUrlTtlSeconds() {
        return presignedUrlTtlSeconds;
    }

    public void setPresignedUrlTtlSeconds(long presignedUrlTtlSeconds) {
        this.presignedUrlTtlSeconds = presignedUrlTtlSeconds > 0 ? presignedUrlTtlSeconds : 3600L;
    }
}
