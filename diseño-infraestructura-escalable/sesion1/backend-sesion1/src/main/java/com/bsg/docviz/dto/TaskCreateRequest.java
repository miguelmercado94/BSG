package com.bsg.docviz.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public record TaskCreateRequest(
        @NotBlank @Size(max = 120) String huCode,
        @NotNull Long cellRepoId,
        @NotBlank @Size(max = 8000) String enunciado
) {}
