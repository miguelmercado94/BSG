package com.bsg.docviz.support;



import com.bsg.docviz.config.DocvizSupportProperties;

import org.slf4j.Logger;

import org.slf4j.LoggerFactory;

import com.bsg.docviz.config.DocvizS3ClientEnabledCondition;

import org.springframework.context.annotation.Conditional;

import org.springframework.stereotype.Service;

import software.amazon.awssdk.core.sync.RequestBody;

import software.amazon.awssdk.services.s3.S3Client;

import software.amazon.awssdk.services.s3.model.CreateBucketRequest;

import software.amazon.awssdk.services.s3.model.DeleteObjectRequest;

import software.amazon.awssdk.services.s3.model.GetObjectRequest;

import software.amazon.awssdk.services.s3.model.HeadBucketRequest;

import software.amazon.awssdk.services.s3.model.ListObjectsV2Request;

import software.amazon.awssdk.services.s3.model.PutObjectRequest;

import software.amazon.awssdk.services.s3.model.S3Exception;

import software.amazon.awssdk.services.s3.model.S3Object;

import software.amazon.awssdk.services.s3.presigner.S3Presigner;

import software.amazon.awssdk.services.s3.presigner.model.GetObjectPresignRequest;



import java.time.Duration;

import java.util.ArrayList;

import java.util.List;

import java.util.Set;

import java.util.concurrent.ConcurrentHashMap;



@Service

@Conditional(DocvizS3ClientEnabledCondition.class)

public class SupportS3Service {



    private static final Logger log = LoggerFactory.getLogger(SupportS3Service.class);



    private final S3Client s3Client;

    private final S3Presigner s3Presigner;

    private final DocvizSupportProperties props;

    private final Set<String> ensuredBuckets = ConcurrentHashMap.newKeySet();



    public SupportS3Service(S3Client s3Client, S3Presigner s3Presigner, DocvizSupportProperties props) {

        this.s3Client = s3Client;

        this.s3Presigner = s3Presigner;

        this.props = props;

    }



    /** Bucket de documentación Markdown de soporte. */

    public String supportBucket() {

        return props.getS3Bucket();

    }



    /**

     * Comprueba existencia del bucket y lo crea (p. ej. LocalStack) si no existe.

     * Idempotente; llamar al arranque para cada bucket DocViz (soporte, borradores, workarea).

     */

    public void ensureBucketExists(String bucket) {

        if (bucket == null || bucket.isBlank()) {

            return;

        }

        if (ensuredBuckets.contains(bucket)) {

            return;

        }

        synchronized (this) {

            if (ensuredBuckets.contains(bucket)) {

                return;

            }

            try {

                s3Client.headBucket(HeadBucketRequest.builder().bucket(bucket).build());

            } catch (S3Exception e) {

                if (e.statusCode() == 404 || e.statusCode() == 403) {

                    log.info("Creando bucket S3: {}", bucket);

                    s3Client.createBucket(CreateBucketRequest.builder().bucket(bucket).build());

                } else {

                    throw e;

                }

            }

            ensuredBuckets.add(bucket);

        }

    }



    /** @deprecated usar {@link #putObject(String, String, byte[], String)} */

    public void putObject(String key, byte[] body, String contentType) {

        putObject(supportBucket(), key, body, contentType);

    }



    public void putObject(String bucket, String key, byte[] body, String contentType) {

        ensureBucketExists(bucket);

        s3Client.putObject(

                PutObjectRequest.builder()

                        .bucket(bucket)

                        .key(key)

                        .contentType(contentType != null ? contentType : "text/markdown; charset=utf-8")

                        .build(),

                RequestBody.fromBytes(body));

    }



    /** Objetos de soporte (bucket {@link #supportBucket()}). */

    public byte[] getObjectBytes(String key) {

        return getObjectBytes(supportBucket(), key);

    }



    public byte[] getObjectBytes(String bucket, String key) {

        return s3Client

                .getObjectAsBytes(GetObjectRequest.builder()

                        .bucket(bucket)

                        .key(key)

                        .build())

                .asByteArray();

    }



    public void deleteObject(String bucket, String key) {

        s3Client.deleteObject(

                DeleteObjectRequest.builder().bucket(bucket).key(key).build());

    }



    /** @deprecated usar {@link #deleteObject(String, String)} con bucket de soporte */

    public void deleteObject(String key) {

        deleteObject(supportBucket(), key);

    }



    /** Lista claves con prefijo en el bucket indicado. */

    public List<String> listObjectKeys(String bucket, String prefix) {

        ensureBucketExists(bucket);

        List<String> keys = new ArrayList<>();

        String token = null;

        do {

            var req = ListObjectsV2Request.builder()

                    .bucket(bucket)

                    .prefix(prefix)

                    .continuationToken(token)

                    .build();

            var resp = s3Client.listObjectsV2(req);

            for (S3Object o : resp.contents()) {

                keys.add(o.key());

            }

            token = Boolean.TRUE.equals(resp.isTruncated()) ? resp.nextContinuationToken() : null;

        } while (token != null);

        return keys;

    }



    /** Lista en el bucket de soporte (compat). */

    public List<String> listObjectKeys(String prefix) {

        return listObjectKeys(supportBucket(), prefix);

    }



    /** Elimina todos los objetos bajo un prefijo en el bucket de soporte. */

    public void deleteObjectsWithPrefix(String prefix) {

        if (prefix == null || prefix.isBlank()) {

            return;

        }

        String bucket = supportBucket();

        List<String> keys = listObjectKeys(bucket, prefix);

        for (String key : keys) {

            deleteObject(bucket, key);

        }

    }



    public String presignGetUrl(String bucket, String key, Duration ttl) {

        var get =

                software.amazon.awssdk.services.s3.model.GetObjectRequest.builder()

                        .bucket(bucket)

                        .key(key)

                        .build();

        var presign =

                GetObjectPresignRequest.builder()

                        .signatureDuration(ttl)

                        .getObjectRequest(get)

                        .build();

        return s3Presigner.presignGetObject(presign).url().toString();

    }



    /** URL firmada en el bucket de soporte. */

    public String presignGetUrl(String key, Duration ttl) {

        return presignGetUrl(supportBucket(), key, ttl);

    }

}


