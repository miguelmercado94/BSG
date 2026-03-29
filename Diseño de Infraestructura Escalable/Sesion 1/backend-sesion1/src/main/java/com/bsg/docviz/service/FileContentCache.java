package com.bsg.docviz.service;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

public class FileContentCache {

    public static final long MAX_TOTAL_BYTES = 2_000_000L;

    private final Map<String, byte[]> byKey = new ConcurrentHashMap<>();

    public void clear() {
        byKey.clear();
    }

    public void put(String key, byte[] data) {
        if (key != null && data != null && data.length <= MAX_TOTAL_BYTES) {
            byKey.put(key, data);
        }
    }

    public byte[] get(String key) {
        return byKey.get(key);
    }
}
