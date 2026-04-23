package com.bsg.docviz.repository;

import java.time.Instant;

public record CellEntity(long id, String name, String description, Instant createdAt, String createdBy) {}
