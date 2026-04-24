package com.bsg.docviz.dto;

import jakarta.validation.constraints.NotBlank;

public record SupportMarkdownUpdateRequest(
        @NotBlank String fileName,
        @NotBlank String content
) {}
