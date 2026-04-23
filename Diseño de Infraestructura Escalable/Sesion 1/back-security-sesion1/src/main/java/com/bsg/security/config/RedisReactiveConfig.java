package com.bsg.security.config;

import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.redis.connection.ReactiveRedisConnectionFactory;
import org.springframework.data.redis.core.ReactiveRedisTemplate;
import org.springframework.data.redis.serializer.RedisSerializationContext;
import org.springframework.data.redis.serializer.RedisSerializer;

/**
 * Cliente Redis reactivo tipado como String/String (revocación en caché).
 * Solo se registra cuando {@code bsg.security.redis.enabled=true}.
 */
@Configuration
@ConditionalOnProperty(name = "bsg.security.redis.enabled", havingValue = "true")
public class RedisReactiveConfig {

    @Bean
    ReactiveRedisTemplate<String, String> bsgReactiveRedisTemplate(ReactiveRedisConnectionFactory factory) {
        RedisSerializationContext<String, String> ctx = RedisSerializationContext
                .<String, String>newSerializationContext(RedisSerializer.string())
                .key(RedisSerializer.string())
                .value(RedisSerializer.string())
                .hashKey(RedisSerializer.string())
                .hashValue(RedisSerializer.string())
                .build();
        return new ReactiveRedisTemplate<>(factory, ctx);
    }
}
