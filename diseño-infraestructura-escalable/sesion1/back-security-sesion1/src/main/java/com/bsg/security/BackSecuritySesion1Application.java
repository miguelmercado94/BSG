package com.bsg.security;

import com.bsg.security.config.DotEnvBootstrap;
import com.bsg.security.config.properties.DynamoDbProperties;
import com.bsg.security.config.properties.RedisCacheProperties;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication
@EnableScheduling
@EnableConfigurationProperties({DynamoDbProperties.class, RedisCacheProperties.class})
public class BackSecuritySesion1Application {

    public static void main(String[] args) {
        DotEnvBootstrap.load();
        SpringApplication.run(BackSecuritySesion1Application.class, args);
    }
}
