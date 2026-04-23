package com.bsg.security.tools;

import com.fasterxml.jackson.annotation.JsonCreator;

public enum ChangeType {
    ADD,
    REMOVE,
    REPLACE;

    @JsonCreator
    public static ChangeType fromString(String value) {
        if (value == null || value.isBlank()) {
            return REPLACE;
        }
        return ChangeType.valueOf(value.trim().toUpperCase());
    }
}
