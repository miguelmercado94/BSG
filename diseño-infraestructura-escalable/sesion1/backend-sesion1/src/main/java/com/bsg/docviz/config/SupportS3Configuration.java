package com.bsg.docviz.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Conditional;
import org.springframework.context.annotation.Configuration;

import software.amazon.awssdk.auth.credentials.DefaultCredentialsProvider;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.presigner.S3Presigner;

@Configuration
@Conditional(DocvizS3ClientEnabledCondition.class)
public class SupportS3Configuration {

    @Bean
    public S3Client supportS3Client(DocvizSupportProperties props) {
        return S3Client.builder()
                .region(Region.of(props.getS3Region()))
                .credentialsProvider(DefaultCredentialsProvider.create())
                .build();
    }

    @Bean
    public S3Presigner supportS3Presigner(DocvizSupportProperties props) {
        return S3Presigner.builder()
                .region(Region.of(props.getS3Region()))
                .credentialsProvider(DefaultCredentialsProvider.create())
                .build();
    }
}
