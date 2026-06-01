package com.bsg.soporterag.configuracion;

import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.redis.connection.ReactiveRedisConnectionFactory;
import org.springframework.data.redis.core.ReactiveRedisTemplate;
import org.springframework.data.redis.serializer.RedisSerializationContext;
import org.springframework.data.redis.serializer.RedisSerializer;

@Configuration
@ConditionalOnProperty(prefix = "soporte-rag.cache.redis", name = "enabled", havingValue = "true")
public class CacheRedisConfiguracion {

    @Bean
    ReactiveRedisTemplate<String, String> soporteRagReactiveRedisTemplate(
            ReactiveRedisConnectionFactory factory) {
        RedisSerializationContext<String, String> context = RedisSerializationContext
                .<String, String>newSerializationContext(RedisSerializer.string())
                .key(RedisSerializer.string())
                .value(RedisSerializer.string())
                .hashKey(RedisSerializer.string())
                .hashValue(RedisSerializer.string())
                .build();
        return new ReactiveRedisTemplate<>(factory, context);
    }
}
