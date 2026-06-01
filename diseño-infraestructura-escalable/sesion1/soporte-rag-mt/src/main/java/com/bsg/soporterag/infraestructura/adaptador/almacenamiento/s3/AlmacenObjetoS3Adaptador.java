package com.bsg.soporterag.infraestructura.adaptador.almacenamiento.s3;

import com.bsg.soporterag.configuracion.AlmacenamientoS3Propiedades;
import com.bsg.soporterag.configuracion.CondicionS3Habilitado;
import com.bsg.soporterag.dominio.modelo.RolBucketS3;
import com.bsg.soporterag.dominio.puerto.salida.AlmacenObjetoPort;
import org.springframework.context.annotation.Conditional;
import org.springframework.stereotype.Component;
import reactor.core.publisher.Mono;
import reactor.core.scheduler.Schedulers;
import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.DeleteObjectRequest;
import software.amazon.awssdk.services.s3.model.GetObjectRequest;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;
import software.amazon.awssdk.services.s3.presigner.S3Presigner;
import software.amazon.awssdk.services.s3.presigner.model.GetObjectPresignRequest;

import java.time.Duration;

@Component
@Conditional(CondicionS3Habilitado.class)
public class AlmacenObjetoS3Adaptador implements AlmacenObjetoPort {

    private final S3Client s3Client;
    private final S3Presigner s3Presigner;
    private final AlmacenamientoS3Propiedades propiedades;

    public AlmacenObjetoS3Adaptador(
            S3Client s3Client,
            S3Presigner s3Presigner,
            AlmacenamientoS3Propiedades propiedades) {
        this.s3Client = s3Client;
        this.s3Presigner = s3Presigner;
        this.propiedades = propiedades;
    }

    @Override
    public Mono<Void> subir(RolBucketS3 rol, String clave, byte[] contenido, String contentType) {
        return Mono.fromRunnable(() -> s3Client.putObject(
                        PutObjectRequest.builder()
                                .bucket(resolverBucket(rol))
                                .key(clave)
                                .contentType(contentType)
                                .build(),
                        RequestBody.fromBytes(contenido)))
                .subscribeOn(Schedulers.boundedElastic())
                .then();
    }

    @Override
    public Mono<byte[]> descargar(RolBucketS3 rol, String clave) {
        return Mono.fromCallable(() -> s3Client.getObjectAsBytes(
                        GetObjectRequest.builder().bucket(resolverBucket(rol)).key(clave).build())
                .asByteArray())
                .subscribeOn(Schedulers.boundedElastic());
    }

    @Override
    public Mono<Void> eliminar(RolBucketS3 rol, String clave) {
        return Mono.fromRunnable(() -> s3Client.deleteObject(
                        DeleteObjectRequest.builder().bucket(resolverBucket(rol)).key(clave).build()))
                .subscribeOn(Schedulers.boundedElastic())
                .then();
    }

    @Override
    public Mono<String> urlPresignadaGet(RolBucketS3 rol, String clave, long ttlSegundos) {
        long ttl = ttlSegundos > 0 ? ttlSegundos : propiedades.presignedUrlTtlSeconds();
        return Mono.fromCallable(() -> {
                    GetObjectPresignRequest presign = GetObjectPresignRequest.builder()
                            .signatureDuration(Duration.ofSeconds(ttl))
                            .getObjectRequest(b -> b.bucket(resolverBucket(rol)).key(clave))
                            .build();
                    return s3Presigner.presignGetObject(presign).url().toString();
                })
                .subscribeOn(Schedulers.boundedElastic());
    }

    @Override
    public String nombreBucket(RolBucketS3 rol) {
        return resolverBucket(rol);
    }

    @Override
    public boolean configurado() {
        return propiedades.enabled();
    }

    private String resolverBucket(RolBucketS3 rol) {
        return propiedades.resolverBucket(rol);
    }
}
