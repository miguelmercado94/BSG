package com.bsg.docviz.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Conditional;
import org.springframework.context.annotation.Configuration;
import software.amazon.awssdk.auth.credentials.AwsBasicCredentials;
import software.amazon.awssdk.auth.credentials.StaticCredentialsProvider;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.S3Configuration;
import software.amazon.awssdk.services.s3.presigner.S3Presigner;

import java.net.URI;

@Configuration
@Conditional(DocvizS3ClientEnabledCondition.class)
public class SupportS3Configuration {

    @Bean
    public S3Client supportS3Client(DocvizSupportProperties props) {
        String endpoint = props.getS3Endpoint();
        if (endpoint == null || endpoint.isBlank()) {
            throw new IllegalStateException(
                    "docviz.support.s3-endpoint es obligatorio cuando docviz.support.enabled o docviz.workspace-s3.enabled");
        }
        AwsBasicCredentials creds = AwsBasicCredentials.create(
                props.getAccessKey().isBlank() ? "test" : props.getAccessKey(),
                props.getSecretKey().isBlank() ? "test" : props.getSecretKey());
        return S3Client.builder()
                .region(Region.of(props.getS3Region()))
                .endpointOverride(URI.create(endpoint))
                .credentialsProvider(StaticCredentialsProvider.create(creds))
                .serviceConfiguration(
                        S3Configuration.builder().pathStyleAccessEnabled(true).build())
                .build();
    }

    @Bean
    public S3Presigner supportS3Presigner(DocvizSupportProperties props) {
        String endpoint = props.effectiveS3PresignEndpoint();
        if (endpoint == null || endpoint.isBlank()) {
            throw new IllegalStateException(
                    "docviz.support.s3-endpoint es obligatorio cuando docviz.support.enabled o docviz.workspace-s3.enabled");
        }
        AwsBasicCredentials creds = AwsBasicCredentials.create(
                props.getAccessKey().isBlank() ? "test" : props.getAccessKey(),
                props.getSecretKey().isBlank() ? "test" : props.getSecretKey());
        return S3Presigner.builder()
                .region(Region.of(props.getS3Region()))
                .endpointOverride(URI.create(endpoint))
                .credentialsProvider(StaticCredentialsProvider.create(creds))
                .serviceConfiguration(
                        S3Configuration.builder().pathStyleAccessEnabled(true).build())
                .build();
    }
}
