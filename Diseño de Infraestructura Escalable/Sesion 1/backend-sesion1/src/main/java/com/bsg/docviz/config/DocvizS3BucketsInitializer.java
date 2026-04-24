package com.bsg.docviz.config;

import com.bsg.docviz.support.SupportS3Service;
import jakarta.annotation.PostConstruct;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.annotation.Conditional;
import org.springframework.stereotype.Component;

/**
 * Al arranque, asegura los tres buckets DocViz (soporte, borradores, workarea) en S3/LocalStack.
 */
@Component
@Conditional(DocvizS3ClientEnabledCondition.class)
public class DocvizS3BucketsInitializer {

    private static final Logger log = LoggerFactory.getLogger(DocvizS3BucketsInitializer.class);

    private final SupportS3Service s3;
    private final DocvizSupportProperties supportProperties;
    private final DocvizWorkspaceS3Properties workspaceProperties;

    public DocvizS3BucketsInitializer(
            SupportS3Service s3,
            DocvizSupportProperties supportProperties,
            DocvizWorkspaceS3Properties workspaceProperties) {
        this.s3 = s3;
        this.supportProperties = supportProperties;
        this.workspaceProperties = workspaceProperties;
    }

    @PostConstruct
    public void ensureDocvizBuckets() {
        try {
            s3.ensureBucketExists(supportProperties.getS3Bucket());
            s3.ensureBucketExists(workspaceProperties.getBorradorBucket());
            s3.ensureBucketExists(workspaceProperties.getWorkareaBucket());
            log.info(
                    "S3 DocViz: buckets comprobados — soporte={}, borradores={}, workarea={}",
                    supportProperties.getS3Bucket(),
                    workspaceProperties.getBorradorBucket(),
                    workspaceProperties.getWorkareaBucket());
        } catch (RuntimeException e) {
            log.error(
                    "S3 DocViz: no se pudieron asegurar los buckets al arranque (¿LocalStack/credenciales?). {}",
                    e.toString());
        }
    }
}

