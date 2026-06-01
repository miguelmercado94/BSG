package com.bsg.soporterag.infraestructura.adaptador.almacenamiento.noop;

import com.bsg.soporterag.dominio.modelo.RolBucketS3;
import com.bsg.soporterag.infraestructura.adaptador.almacenamiento.s3.buckets3.BucketS3Adaptador;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

@Component
@ConditionalOnProperty(prefix = "soporte-rag.almacenamiento.s3", name = "enabled", havingValue = "false")
public class BucketS3AdaptadorNoOp implements BucketS3Adaptador {

    private static final String MENSAJE = "S3 no configurado";

    @Override
    public Mono<Void> crearCarpeta(RolBucketS3 rol, String folderPath) {
        return Mono.error(new IllegalStateException(MENSAJE));
    }

    @Override
    public Mono<Void> crearArchivo(RolBucketS3 rol, String filePath, byte[] contenido, String contentType) {
        return Mono.error(new IllegalStateException(MENSAJE));
    }

    @Override
    public Mono<byte[]> obtenerArchivo(RolBucketS3 rol, String filePath) {
        return Mono.error(new IllegalStateException(MENSAJE));
    }

    @Override
    public Flux<String> listarArchivos(RolBucketS3 rol, String folderPath) {
        return Flux.error(new IllegalStateException(MENSAJE));
    }

    @Override
    public Mono<Void> eliminarCarpeta(RolBucketS3 rol, String folderPath) {
        return Mono.error(new IllegalStateException(MENSAJE));
    }

    @Override
    public Mono<String> urlPresignadaGet(RolBucketS3 rol, String clave, long ttlSegundos) {
        return Mono.error(new IllegalStateException(MENSAJE));
    }
}
