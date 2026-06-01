package com.bsg.soporterag.aplicacion.dto.response;

import java.util.List;
import java.util.Map;

public record SaludInfraestructuraDto(
        String aplicacion,
        List<String> perfiles,
        String proveedorEmbeddings,
        int dimensionesEmbedding,
        Map<String, String> tablasRag,
        Map<String, String> bucketsS3,
        boolean s3Configurado,
        String modoS3,
        boolean cacheRedisActiva
) {
}
