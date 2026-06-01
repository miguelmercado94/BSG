package com.bsg.soporterag.infraestructura.adaptador.almacenamiento.s3.buckets3;

import org.springframework.util.StringUtils;

/**
 * Normalización de claves S3 (sin barra inicial; prefijos de carpeta con {@code /} final).
 */
final class ClaveS3Util {

    private ClaveS3Util() {
    }

    static String normalizarClave(String path) {
        if (!StringUtils.hasText(path)) {
            throw new IllegalArgumentException("La ruta S3 es obligatoria");
        }
        String clave = path.trim().replace('\\', '/');
        while (clave.startsWith("/")) {
            clave = clave.substring(1);
        }
        return clave;
    }

    static String claveCarpeta(String folderPath) {
        String clave = normalizarClave(folderPath);
        return clave.endsWith("/") ? clave : clave + "/";
    }

    static String prefijoListado(String folderPath) {
        return claveCarpeta(folderPath);
    }

    static boolean esMarcadorCarpeta(String key) {
        return key != null && key.endsWith("/");
    }
}
