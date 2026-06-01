package com.bsg.soporterag.infraestructura.adaptador.almacenamiento.s3.buckets3;

import com.bsg.soporterag.dominio.modelo.RolBucketS3;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

/**
 * Adaptador de operaciones sobre un bucket S3 concreto (rol {@link RolBucketS3}).
 */
public interface BucketS3Adaptador {

    /**
     * Crea un prefijo tipo carpeta (objeto vacío con clave terminada en {@code /}).
     */
    Mono<Void> crearCarpeta(RolBucketS3 rol, String folderPath);

    /**
     * Sube un archivo (objeto) en la clave indicada.
     */
    Mono<Void> crearArchivo(RolBucketS3 rol, String filePath, byte[] contenido, String contentType);

    /** Descarga el contenido de un objeto por su clave. */
    Mono<byte[]> obtenerArchivo(RolBucketS3 rol, String filePath);

    /**
     * Lista las claves de objetos (archivos) bajo {@code folderPath}; excluye marcadores de carpeta.
     */
    Flux<String> listarArchivos(RolBucketS3 rol, String folderPath);

    /**
     * Elimina todos los objetos bajo un prefijo (carpeta).
     */
    Mono<Void> eliminarCarpeta(RolBucketS3 rol, String folderPath);

    /**
     * Genera una URL de lectura pre-firmada para un objeto.
     */
    Mono<String> urlPresignadaGet(RolBucketS3 rol, String clave, long ttlSegundos);
}
