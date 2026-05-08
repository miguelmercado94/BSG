package com.bsg.docviz.dto;

import jakarta.validation.constraints.NotBlank;

/** Cuerpo de POST .../ingest-one */
public record PendingIngestOneRequest(@NotBlank String path) {}
