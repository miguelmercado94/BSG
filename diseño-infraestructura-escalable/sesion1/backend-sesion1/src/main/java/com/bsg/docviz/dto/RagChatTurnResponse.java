package com.bsg.docviz.dto;

import java.util.List;

/** Respuesta JSON de un turno completo de chat RAG ({@code POST /vector/chat/rag-turn}). */
public class RagChatTurnResponse {

    private String answer;
    private List<String> sources;
    private List<WorkAreaProposalItemDto> proposals;

    public String getAnswer() {
        return answer;
    }

    public void setAnswer(String answer) {
        this.answer = answer;
    }

    public List<String> getSources() {
        return sources;
    }

    public void setSources(List<String> sources) {
        this.sources = sources;
    }

    public List<WorkAreaProposalItemDto> getProposals() {
        return proposals;
    }

    public void setProposals(List<WorkAreaProposalItemDto> proposals) {
        this.proposals = proposals;
    }
}
