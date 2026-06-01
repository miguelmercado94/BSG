package com.bsg.soporterag.infraestructura.adaptador.almacenamiento.noop;

import com.bsg.soporterag.dominio.modelo.RolBucketS3;
import com.bsg.soporterag.dominio.puerto.salida.AlmacenObjetoPort;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;
import reactor.core.publisher.Mono;

@Component
@ConditionalOnProperty(prefix = "soporte-rag.almacenamiento.s3", name = "enabled", havingValue = "false")
public class AlmacenObjetoNoOpAdaptador implements AlmacenObjetoPort {

    @Override
    public Mono<Void> subir(RolBucketS3 rol, String clave, byte[] contenido, String contentType) {
        return Mono.error(new IllegalStateException("S3 no configurado"));
    }

    @Override
    public Mono<byte[]> descargar(RolBucketS3 rol, String clave) {
        return Mono.error(new IllegalStateException("S3 no configurado"));
    }

    @Override
    public Mono<Void> eliminar(RolBucketS3 rol, String clave) {
        return Mono.error(new IllegalStateException("S3 no configurado"));
    }

    @Override
    public Mono<String> urlPresignadaGet(RolBucketS3 rol, String clave, long ttlSegundos) {
        return Mono.error(new IllegalStateException("S3 no configurado"));
    }

    @Override
    public String nombreBucket(RolBucketS3 rol) {
        return "";
    }

    @Override
    public boolean configurado() {
        return false;
    }
}
