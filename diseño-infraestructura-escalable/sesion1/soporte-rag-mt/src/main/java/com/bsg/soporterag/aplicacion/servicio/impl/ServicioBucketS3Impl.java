package com.bsg.soporterag.aplicacion.servicio.impl;

import com.bsg.soporterag.aplicacion.servicio.ServicioBucketS3;
import com.bsg.soporterag.dominio.modelo.RolBucketS3;
import com.bsg.soporterag.infraestructura.adaptador.almacenamiento.s3.buckets3.BucketS3Adaptador;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

@Service
public class ServicioBucketS3Impl implements ServicioBucketS3 {

    private final BucketS3Adaptador bucketS3Adaptador;

    public ServicioBucketS3Impl(BucketS3Adaptador bucketS3Adaptador) {
        this.bucketS3Adaptador = bucketS3Adaptador;
    }

    @Override
    public Mono<Void> crearCarpeta(RolBucketS3 rol, String folderPath) {
        return bucketS3Adaptador.crearCarpeta(rol, folderPath);
    }

    @Override
    public Mono<Void> crearArchivo(RolBucketS3 rol, String filePath, byte[] contenido, String contentType) {
        return bucketS3Adaptador.crearArchivo(rol, filePath, contenido, contentType);
    }

    @Override
    public Mono<byte[]> obtenerArchivo(RolBucketS3 rol, String filePath) {
        return bucketS3Adaptador.obtenerArchivo(rol, filePath);
    }

    @Override
    public Flux<String> listarArchivos(RolBucketS3 rol, String folderPath) {
        return bucketS3Adaptador.listarArchivos(rol, folderPath);
    }

    @Override
    public Mono<Void> eliminarCarpeta(RolBucketS3 rol, String folderPath) {
        return bucketS3Adaptador.eliminarCarpeta(rol, folderPath);
    }

    @Override
    public Mono<String> generarUrlLectura(RolBucketS3 rol, String clave) {
        return bucketS3Adaptador.urlPresignadaGet(rol, clave, 0);
    }
}
