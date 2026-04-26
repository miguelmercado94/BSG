package com.bsg.security.config;

import java.net.URI;

import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Profile;

import com.bsg.security.config.properties.DynamoDbProperties;

import software.amazon.awssdk.auth.credentials.AwsBasicCredentials;
import software.amazon.awssdk.auth.credentials.DefaultCredentialsProvider;
import software.amazon.awssdk.auth.credentials.StaticCredentialsProvider;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.dynamodb.DynamoDbAsyncClient;

@Configuration
@ConditionalOnProperty(name = "bsg.security.aws.dynamodb.enabled", havingValue = "true")
public class DynamoDbClientConfig {

    @Bean
    @Profile("dev")
    public DynamoDbAsyncClient dynamoDbAsyncClientDev(DynamoDbProperties properties) {
        var builder = DynamoDbAsyncClient.builder()
                .region(Region.of(properties.region() != null && !properties.region().isBlank()
                        ? properties.region()
                        : "us-east-1"))
                .credentialsProvider(StaticCredentialsProvider.create(
                        AwsBasicCredentials.create("test", "test")));
                        
        if (properties.endpoint() != null && !properties.endpoint().isBlank()) {
            builder.endpointOverride(URI.create(properties.endpoint().trim()));
        }
        return builder.build();
    }

    @Bean
    @Profile("pdn")
    public DynamoDbAsyncClient dynamoDbAsyncClientPdn(DynamoDbProperties properties) {
        return DynamoDbAsyncClient.builder()
                .region(Region.of(properties.region() != null && !properties.region().isBlank()
                        ? properties.region()
                        : "us-east-1"))
                .credentialsProvider(DefaultCredentialsProvider.create())
                .build();
    }
}
