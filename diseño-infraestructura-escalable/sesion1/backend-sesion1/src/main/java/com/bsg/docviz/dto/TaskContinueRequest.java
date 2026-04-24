package com.bsg.docviz.dto;

import jakarta.validation.constraints.Positive;

public record TaskContinueRequest(@Positive long taskId) {}
