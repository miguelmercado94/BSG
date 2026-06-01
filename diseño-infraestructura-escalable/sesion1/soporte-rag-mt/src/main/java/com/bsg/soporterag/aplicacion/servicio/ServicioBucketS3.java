package com.bsg.soporterag.aplicacion.servicio;

import com.bsg.soporterag.dominio.modelo.RolBucketS3;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

/**
 * Servicio de aplicación sobre buckets S3 (wrapper de {@link com.bsg.soporterag.infraestructura.adaptador.almacenamiento.s3.buckets3.BucketS3Adaptador}).
 */
public interface ServicioBucketS3 {

    Mono<Void> crearCarpeta(RolBucketS3 rol, String folderPath);

    Mono<Void> crearArchivo(RolBucketS3 rol, String filePath, byte[] contenido, String contentType);

    Mono<byte[]> obtenerArchivo(RolBucketS3 rol, String filePath);

    Flux<String> listarArchivos(RolBucketS3 rol, String folderPath);

    Mono<Void> eliminarCarpeta(RolBucketS3 rol, String folderPath);

    Mono<String> generarUrlLectura(RolBucketS3 rol, String clave);
}
