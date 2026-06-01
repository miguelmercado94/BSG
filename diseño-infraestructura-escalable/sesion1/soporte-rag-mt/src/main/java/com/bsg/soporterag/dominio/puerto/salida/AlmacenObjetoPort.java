package com.bsg.soporterag.dominio.puerto.salida;

import com.bsg.soporterag.dominio.modelo.RolBucketS3;
import reactor.core.publisher.Mono;

public interface AlmacenObjetoPort {

    Mono<Void> subir(RolBucketS3 rol, String clave, byte[] contenido, String contentType);

    Mono<byte[]> descargar(RolBucketS3 rol, String clave);

    Mono<Void> eliminar(RolBucketS3 rol, String clave);

    Mono<String> urlPresignadaGet(RolBucketS3 rol, String clave, long ttlSegundos);

    String nombreBucket(RolBucketS3 rol);

    boolean configurado();
}
