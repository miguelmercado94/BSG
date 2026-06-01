package com.bsg.soporterag.configuracion;

import com.bsg.soporterag.dominio.modelo.RolBucketS3;
import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "soporte-rag.almacenamiento.s3")
public record AlmacenamientoS3Propiedades(
        boolean enabled,
        String region,
        String endpoint,
        String presignEndpoint,
        String accessKey,
        String secretKey,
        /** Bucket markdown/documentos de soporte (backend: {@code docviz.support.s3-bucket}). */
        String bucketSoporte,
        /** Bucket borradores área de trabajo (backend: {@code docviz.workspace-s3.borrador-bucket}). */
        String bucketBorradores,
        /** Bucket workarea aceptada (backend: {@code docviz.workspace-s3.workarea-bucket}). */
        String bucketWorkarea,
        String soporteRepoPrefixTemplate,
        String soporteSessionPrefixTemplate,
        String borradoresPrefixTemplate,
        String workareaPrefixTemplate,
        long presignedUrlTtlSeconds
) {

    public boolean usaEndpointPersonalizado() {
        return endpoint != null && !endpoint.isBlank();
    }

    public String endpointPresignadoEfectivo() {
        return presignEndpoint != null && !presignEndpoint.isBlank() ? presignEndpoint : endpoint;
    }

    public String resolverBucket(RolBucketS3 rol) {
        return switch (rol) {
            case SOPORTE -> bucketSoporte;
            case BORRADORES -> bucketBorradores;
            case WORKAREA -> bucketWorkarea;
        };
    }
}
