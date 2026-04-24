package com.bsg.security.config.properties;

import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * Configuración DynamoDB (LocalStack o AWS). Revocación de tokens JWT.
 */
@ConfigurationProperties(prefix = "bsg.security.aws.dynamodb")
public record DynamoDbProperties(
        boolean enabled,
        String endpoint,
        String region,
        String revokedTokensTable,
        boolean createTableIfNotExists
) {
}
