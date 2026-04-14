package com.bsg.docviz.dto;

import java.util.List;

/**
 * Un turno persistido en Firestore ({@code users/{userId}/messages/{docId}}).
 */
public class ChatHistoryEntryDto {

    private String id;
    private String question;
    private String answer;
    private List<String> sources;
    private String repoLabel;
    /** ISO-8601 UTC o null si el documento no tenía timestamp */
    private String createdAt;

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getQuestion() {
        return question;
    }

    public void setQuestion(String question) {
        this.question = question;
    }

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

    public String getRepoLabel() {
        return repoLabel;
    }

    public void setRepoLabel(String repoLabel) {
        this.repoLabel = repoLabel;
    }

    public String getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(String createdAt) {
        this.createdAt = createdAt;
    }
}
