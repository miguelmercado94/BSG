package com.bsg.docviz.dto;

import jakarta.validation.constraints.NotNull;

import java.util.List;

public record CellRepoAssignRequest(@NotNull List<Long> repoIds) {}
