package com.bsg.docviz.dto;

import jakarta.validation.constraints.NotBlank;

public class VectorChatRequest {

    @NotBlank
    private String question;

    public String getQuestion() {
        return question;
    }

    public void setQuestion(String question) {
        this.question = question;
    }
}
