package com.bsg.soporterag.configuracion;

import com.bsg.soporterag.dominio.modelo.FuenteRag;
import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "soporte-rag.vector")
public record VectorPropiedades(
        int embeddingDimensions,
        int ragTopK,
        int chunkSize,
        int chunkOverlap,
        int maxFileSizeMb,
        int embeddingBatchSize,
        String embeddingsProvider,
        String tablaGit,
        String tablaSoporte
) {

    public String nombreTabla(FuenteRag fuente) {
        return switch (fuente) {
            case GIT -> tablaGit;
            case SOPORTE -> tablaSoporte;
        };
    }
}
