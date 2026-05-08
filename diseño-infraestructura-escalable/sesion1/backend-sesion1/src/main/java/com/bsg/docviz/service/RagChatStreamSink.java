package com.bsg.docviz.service;

import com.bsg.docviz.dto.WorkAreaProposalItemDto;

import java.util.List;

/** Callbacks durante la generación de un turno RAG (se acumulan para la respuesta HTTP). */
public interface RagChatStreamSink {

    void onStart(List<String> sources);

    void onDelta(String text);

    void onProposals(List<WorkAreaProposalItemDto> proposals);

    void onDone();
}
