package com.bsg.docviz.config;

import java.net.URI;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Conditional;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Profile;

import software.amazon.awssdk.auth.credentials.AwsBasicCredentials;
import software.amazon.awssdk.auth.credentials.DefaultCredentialsProvider;
import software.amazon.awssdk.auth.credentials.StaticCredentialsProvider;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.S3Configuration;
import software.amazon.awssdk.services.s3.presigner.S3Presigner;

@Configuration
@Conditional(DocvizS3ClientEnabledCondition.class)
public class SupportS3Configuration {

    @Bean
    @Profile("!pdn")
    public S3Client supportS3ClientDev(DocvizSupportProperties props) {
        String endpoint = props.getS3Endpoint();
        if (endpoint == null || endpoint.isBlank()) {
            throw new IllegalStateException(
                    "docviz.support.s3-endpoint es obligatorio en local/develop");
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
    @Profile("!pdn")
    public S3Presigner supportS3PresignerDev(DocvizSupportProperties props) {
        String endpoint = props.effectiveS3PresignEndpoint();
        if (endpoint == null || endpoint.isBlank()) {
            throw new IllegalStateException(
                    "docviz.support.s3-endpoint es obligatorio en local/develop");
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

    @Bean
    @Profile("pdn")
    public S3Client supportS3ClientPdn(DocvizSupportProperties props) {
        return S3Client.builder()
                .region(Region.of(props.getS3Region()))
                .credentialsProvider(DefaultCredentialsProvider.create())
                .build();
    }

    @Bean
    @Profile("pdn")
    public S3Presigner supportS3PresignerPdn(DocvizSupportProperties props) {
        return S3Presigner.builder()
                .region(Region.of(props.getS3Region()))
                .credentialsProvider(DefaultCredentialsProvider.create())
                .build();
    }
}
