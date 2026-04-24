package com.bsg.docviz.dto;

import java.time.Instant;

public record CellResponse(long id, String name, String description, Instant createdAt, String createdBy) {}
