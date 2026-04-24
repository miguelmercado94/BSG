package com.bsg.docviz.dto;

import java.util.List;

public record TaskArtifactRestoreResponse(
        List<String> borradoresRestored,
        List<String> workareaRestored,
        List<RestoredWorkAreaProposalDto> proposals) {}
