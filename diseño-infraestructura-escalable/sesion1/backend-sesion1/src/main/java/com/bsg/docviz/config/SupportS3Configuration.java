package com.bsg.docviz.config;

import java.net.URI;

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
import software.amazon.awssdk.services.s3.presigner.S3Presigner;

@Configuration
@Conditional(DocvizS3ClientEnabledCondition.class)
public class SupportS3Configuration {

    @Bean
    public S3Client supportS3Client(DocvizSupportProperties props) {
        var builder = S3Client.builder()
                .region(Region.of(props.getS3Region()))
                .credentialsProvider(resolveCredentialsProvider(props));

        if (usesCustomEndpoint(props)) {
            builder.endpointOverride(URI.create(props.getS3Endpoint().trim()))
                    .serviceConfiguration(
                            S3Configuration.builder().pathStyleAccessEnabled(true).build());
        }
        return builder.build();
    }

    @Bean
    public S3Presigner supportS3Presigner(DocvizSupportProperties props) {
        var builder = S3Presigner.builder()
                .region(Region.of(props.getS3Region()))
                .credentialsProvider(resolveCredentialsProvider(props));

        if (usesCustomEndpoint(props)) {
            builder.endpointOverride(URI.create(props.getS3Endpoint().trim()));
        }
        return builder.build();
    }

    private static boolean usesCustomEndpoint(DocvizSupportProperties props) {
        return props.getS3Endpoint() != null && !props.getS3Endpoint().isBlank();
    }

    /**
     * Sin {@code docviz.support.s3-endpoint}: AWS real → {@link DefaultCredentialsProvider} (p. ej. IAM del task en ECS).
     * Con endpoint (LocalStack): credenciales estáticas solo si access-key y secret-key están definidas.
     */
    private static AwsCredentialsProvider resolveCredentialsProvider(DocvizSupportProperties props) {
        if (usesCustomEndpoint(props)
                && !props.getAccessKey().isBlank()
                && !props.getSecretKey().isBlank()) {
            return StaticCredentialsProvider.create(
                    AwsBasicCredentials.create(props.getAccessKey(), props.getSecretKey()));
        }
        return DefaultCredentialsProvider.create();
    }
}
