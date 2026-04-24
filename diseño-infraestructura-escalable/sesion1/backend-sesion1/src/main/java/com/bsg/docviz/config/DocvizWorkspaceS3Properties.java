package com.bsg.docviz.config;



import org.springframework.boot.context.properties.ConfigurationProperties;



/**

 * Buckets S3 dedicados para borradores y workarea (separados del bucket de soporte).

 * Claves: {@code {userId}}, {@code {taskCode}}; opcional {@code {vectorNamespace}} en la raíz.

 */

@ConfigurationProperties(prefix = "docviz.workspace-s3")
public class DocvizWorkspaceS3Properties {

    /** Bucket para borradores (objeto S3 nombrado {@code *_vN.ext}; en disco el borrador sigue siendo {@code *.txt} hasta aceptar). */
    private String borradorBucket = "borradores";

    /** Bucket para copias aceptadas / indexadas en workarea. */
    private String workareaBucket = "workarea";

    /**
     * Prefijo opcional antes de usuario/tarea. Vacío = solo {@code {userId}/{taskCode}/…}.
     * Por defecto vacío (tres buckets separados; no hace falta prefijo de namespace en la clave).
     */
    private String keyRootTemplate = "";

    /**
     * Tras {@code keyRootTemplate}: carpeta lógica por usuario y tarea.
     * Formato: {@code {userId}/{taskCode}/}
     */
    private String borradoresPrefixTemplate = "{userId}/{taskCode}/";

    private String workareaPrefixTemplate = "{userId}/{taskCode}/";

    public String getBorradorBucket() {
        return borradorBucket;
    }

    public void setBorradorBucket(String borradorBucket) {
        this.borradorBucket = borradorBucket != null && !borradorBucket.isBlank() ? borradorBucket.trim() : "borradores";
    }

    public String getWorkareaBucket() {
        return workareaBucket;
    }

    public void setWorkareaBucket(String workareaBucket) {
        this.workareaBucket = workareaBucket != null && !workareaBucket.isBlank() ? workareaBucket.trim() : "workarea";
    }

    public String getKeyRootTemplate() {
        return keyRootTemplate;
    }

    public void setKeyRootTemplate(String keyRootTemplate) {
        this.keyRootTemplate = keyRootTemplate != null ? keyRootTemplate : "";
    }

    public String getBorradoresPrefixTemplate() {
        return borradoresPrefixTemplate;
    }

    public void setBorradoresPrefixTemplate(String borradoresPrefixTemplate) {
        this.borradoresPrefixTemplate =
                borradoresPrefixTemplate != null && !borradoresPrefixTemplate.isBlank()
                        ? borradoresPrefixTemplate.trim()
                        : "{userId}/{taskCode}/";
    }

    public String getWorkareaPrefixTemplate() {
        return workareaPrefixTemplate;
    }

    public void setWorkareaPrefixTemplate(String workareaPrefixTemplate) {
        this.workareaPrefixTemplate =
                workareaPrefixTemplate != null && !workareaPrefixTemplate.isBlank()
                        ? workareaPrefixTemplate.trim()
                        : "{userId}/{taskCode}/";
    }
}
