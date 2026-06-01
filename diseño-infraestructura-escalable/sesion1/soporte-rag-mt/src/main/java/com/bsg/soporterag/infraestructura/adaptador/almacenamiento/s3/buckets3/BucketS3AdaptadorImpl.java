package com.bsg.soporterag.infraestructura.adaptador.almacenamiento.s3.buckets3;

import com.bsg.soporterag.configuracion.AlmacenamientoS3Propiedades;
import com.bsg.soporterag.configuracion.CondicionS3Habilitado;
import com.bsg.soporterag.dominio.modelo.RolBucketS3;
import org.springframework.context.annotation.Conditional;
import org.springframework.stereotype.Component;
import org.springframework.util.CollectionUtils;
import org.springframework.util.StringUtils;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;
import reactor.core.scheduler.Schedulers;
import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.*;
import software.amazon.awssdk.services.s3.presigner.S3Presigner;
import software.amazon.awssdk.services.s3.presigner.model.GetObjectPresignRequest;

import java.time.Duration;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

@Component
@Conditional(CondicionS3Habilitado.class)
public class BucketS3AdaptadorImpl implements BucketS3Adaptador {

    private static final String CONTENT_TYPE_OCTET = "application/octet-stream";
    private static final String CONTENT_TYPE_FOLDER = "application/x-directory";

    private final S3Client s3Client;
    private final S3Presigner s3Presigner;
    private final AlmacenamientoS3Propiedades propiedades;

    public BucketS3AdaptadorImpl(S3Client s3Client, S3Presigner s3Presigner, AlmacenamientoS3Propiedades propiedades) {
        this.s3Client = s3Client;
        this.s3Presigner = s3Presigner;
        this.propiedades = propiedades;
    }

    @Override
    public Mono<Void> crearCarpeta(RolBucketS3 rol, String folderPath) {
        String clave = ClaveS3Util.claveCarpeta(folderPath);
        return Mono.fromRunnable(() -> s3Client.putObject(
                        PutObjectRequest.builder()
                                .bucket(resolverBucket(rol))
                                .key(clave)
                                .contentType(CONTENT_TYPE_FOLDER)
                                .build(),
                        RequestBody.empty()))
                .subscribeOn(Schedulers.boundedElastic())
                .then();
    }

    @Override
    public Mono<Void> crearArchivo(RolBucketS3 rol, String filePath, byte[] contenido, String contentType) {
        String clave = ClaveS3Util.normalizarClave(filePath);
        if (ClaveS3Util.esMarcadorCarpeta(clave)) {
            return Mono.error(new IllegalArgumentException(
                    "La ruta de archivo no puede terminar en '/': " + filePath));
        }
        byte[] bytes = contenido != null ? contenido : new byte[0];
        String tipo = StringUtils.hasText(contentType) ? contentType : CONTENT_TYPE_OCTET;
        return Mono.fromRunnable(() -> s3Client.putObject(
                        PutObjectRequest.builder()
                                .bucket(resolverBucket(rol))
                                .key(clave)
                                .contentType(tipo)
                                .build(),
                        RequestBody.fromBytes(bytes)))
                .subscribeOn(Schedulers.boundedElastic())
                .then();
    }

    @Override
    public Mono<byte[]> obtenerArchivo(RolBucketS3 rol, String filePath) {
        String clave = ClaveS3Util.normalizarClave(filePath);
        return Mono.fromCallable(() -> s3Client.getObjectAsBytes(
                        GetObjectRequest.builder()
                                .bucket(resolverBucket(rol))
                                .key(clave)
                                .build())
                .asByteArray())
                .subscribeOn(Schedulers.boundedElastic());
    }

    @Override
    public Flux<String> listarArchivos(RolBucketS3 rol, String folderPath) {
        String bucket = resolverBucket(rol);
        String prefijo = ClaveS3Util.prefijoListado(folderPath);
        return Mono.fromCallable(() -> listarClavesArchivo(bucket, prefijo))
                .subscribeOn(Schedulers.boundedElastic())
                .flatMapMany(Flux::fromIterable);
    }

    @Override
    public Mono<Void> eliminarCarpeta(RolBucketS3 rol, String folderPath) {
        String bucket = resolverBucket(rol);
        String prefijo = ClaveS3Util.prefijoListado(folderPath);

        return listarArchivos(rol, folderPath)
                .collectList()
                .flatMap(claves -> {
                    if (CollectionUtils.isEmpty(claves)) {
                        return Mono.empty();
                    }
                    List<ObjectIdentifier> objectIdentifiers = claves.stream()
                            .map(clave -> ObjectIdentifier.builder().key(clave).build())
                            .collect(Collectors.toList());

                    DeleteObjectsRequest deleteRequest = DeleteObjectsRequest.builder()
                            .bucket(bucket)
                            .delete(Delete.builder().objects(objectIdentifiers).build())
                            .build();

                    return Mono.fromRunnable(() -> s3Client.deleteObjects(deleteRequest));
                })
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

    private List<String> listarClavesArchivo(String bucket, String prefijo) {
        List<String> claves = new ArrayList<>();
        ListObjectsV2Request request = ListObjectsV2Request.builder()
                .bucket(bucket)
                .prefix(prefijo)
                .build();
        s3Client.listObjectsV2Paginator(request)
                .stream()
                .flatMap(page -> page.contents().stream())
                .map(S3Object::key)
                // No filtramos el marcador de carpeta aquí para que también se pueda borrar
                .forEach(claves::add);
        return claves;
    }

    private String resolverBucket(RolBucketS3 rol) {
        return propiedades.resolverBucket(rol);
    }
}
