package com.bsg.security.infrastructure.adapter.cache;

import com.bsg.security.util.TokenHashUtils;

/**
 * Convención de claves Redis para revocación (sustituible por otro backend vía {@link com.bsg.security.application.port.output.cache.TokenRevocationCachePort}).
 */
public final class RedisTokenCacheKeys {

    private RedisTokenCacheKeys() {
    }

    public static String accessKey(String keyPrefix, String accessJwt) {
        return keyPrefix + "access:" + TokenHashUtils.sha256Hex(accessJwt);
    }

    public static String refreshKey(String keyPrefix, String refreshJwt) {
        return keyPrefix + "refresh:" + TokenHashUtils.sha256Hex(refreshJwt);
    }

    public static String accessKeyPattern(String keyPrefix) {
        return keyPrefix + "access:*";
    }
}
