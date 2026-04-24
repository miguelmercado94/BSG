package com.bsg.docviz.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record CellRequest(
        @NotBlank @Size(max = 200) String name,
        @Size(max = 4000) String description
) {}
