package com.bsg.soporterag.configuracion;

import java.net.URI;
import java.util.List;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.ApplicationRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Conditional;
import org.springframework.context.annotation.Configuration;

import software.amazon.awssdk.auth.credentials.AwsBasicCredentials;
import software.amazon.awssdk.auth.credentials.AwsCredentialsProvider;
import software.amazon.awssdk.auth.credentials.DefaultCredentialsProvider;
import software.amazon.awssdk.auth.credentials.StaticCredentialsProvider;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.S3Configuration;
import software.amazon.awssdk.services.s3.model.BucketAlreadyExistsException;
import software.amazon.awssdk.services.s3.model.BucketAlreadyOwnedByYouException;
import software.amazon.awssdk.services.s3.model.CreateBucketRequest;
import software.amazon.awssdk.services.s3.presigner.S3Presigner;

/**
 * Cliente S3: LocalStack (endpoint + path-style + credenciales estáticas) vs AWS real (IAM del task).
 */
@Configuration
@Conditional(CondicionS3Habilitado.class)
public class AlmacenamientoS3Configuracion {

    private static final Logger log = LoggerFactory.getLogger(AlmacenamientoS3Configuracion.class);

    @Bean
    public S3Client s3Client(AlmacenamientoS3Propiedades propiedades) {
        var builder = S3Client.builder()
                .region(Region.of(propiedades.region()))
                .credentialsProvider(resolverCredenciales(propiedades));

        if (propiedades.usaEndpointPersonalizado()) {
            builder.endpointOverride(URI.create(propiedades.endpoint().trim()))
                    .serviceConfiguration(
                            S3Configuration.builder().pathStyleAccessEnabled(true).build());
        }
        return builder.build();
    }

    @Bean
    public S3Presigner s3Presigner(AlmacenamientoS3Propiedades propiedades) {
        var builder = S3Presigner.builder()
                .region(Region.of(propiedades.region()))
                .credentialsProvider(resolverCredenciales(propiedades));

        if (propiedades.usaEndpointPersonalizado()) {
            builder.endpointOverride(URI.create(propiedades.endpoint().trim()));
        }
        return builder.build();
    }

    @Bean
    public ApplicationRunner inicializarBucketsS3(S3Client s3Client, AlmacenamientoS3Propiedades propiedades) {
        return args -> {
            // Solo intentamos crear los buckets si estamos usando LocalStack (endpoint personalizado)
            // En AWS real, los buckets ya existen (creados por Terraform).
            if (propiedades.usaEndpointPersonalizado()) {
                log.info("Entorno local detectado. Verificando/creando buckets S3 en LocalStack...");
                List<String> buckets = List.of(
                        propiedades.bucketSoporte(),
                        propiedades.bucketBorradores(),
                        propiedades.bucketWorkarea()
                );

                for (String bucketName : buckets) {
                    try {
                        s3Client.createBucket(CreateBucketRequest.builder().bucket(bucketName).build());
                        log.info("Bucket creado: {}", bucketName);
                    } catch (BucketAlreadyExistsException | BucketAlreadyOwnedByYouException e) {
                        log.info("El bucket ya existe: {}", bucketName);
                    } catch (Exception e) {
                        log.error("Error al intentar crear el bucket: {}", bucketName, e);
                    }
                }
            }
        };
    }

    private static AwsCredentialsProvider resolverCredenciales(AlmacenamientoS3Propiedades propiedades) {
        if (propiedades.usaEndpointPersonalizado()
                && propiedades.accessKey() != null
                && !propiedades.accessKey().isBlank()
                && propiedades.secretKey() != null
                && !propiedades.secretKey().isBlank()) {
            return StaticCredentialsProvider.create(
                    AwsBasicCredentials.create(propiedades.accessKey(), propiedades.secretKey()));
        }
        return DefaultCredentialsProvider.create();
    }
}
