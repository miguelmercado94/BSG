package com.bsg.docviz.dto.ws;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonSetter;

/**
 * Mensaje entrante del cliente WebSocket del chat RAG (JSON).
 */
@JsonIgnoreProperties(ignoreUnknown = true)
@JsonInclude(JsonInclude.Include.NON_EMPTY)
public class RagChatClientMessage {

    private String question;
    private String user;
    private String role;
    private String taskHuCode;
    private Long taskId;
    private String conversationId;
    /** Nombre de célula (área de trabajo) para Firestore y S3; opcional. */
    private String cellName;

    /** Acepta número o string en JSON (clientes JS envían a veces uno u otro). */
    @JsonSetter("taskId")
    public void setTaskIdFlexible(Object value) {
        if (value == null) {
            this.taskId = null;
            return;
        }
        if (value instanceof Number n) {
            this.taskId = n.longValue();
            return;
        }
        try {
            this.taskId = Long.parseLong(String.valueOf(value).trim());
        } catch (NumberFormatException e) {
            this.taskId = null;
        }
    }

    public String getQuestion() {
        return question;
    }

    public void setQuestion(String question) {
        this.question = question;
    }

    public String getUser() {
        return user;
    }

    public void setUser(String user) {
        this.user = user;
    }

    public String getRole() {
        return role;
    }

    public void setRole(String role) {
        this.role = role;
    }

    public String getTaskHuCode() {
        return taskHuCode;
    }

    public void setTaskHuCode(String taskHuCode) {
        this.taskHuCode = taskHuCode;
    }

    public Long getTaskId() {
        return taskId;
    }

    public String getConversationId() {
        return conversationId;
    }

    public void setConversationId(String conversationId) {
        this.conversationId = conversationId;
    }

    public String getCellName() {
        return cellName;
    }

    public void setCellName(String cellName) {
        this.cellName = cellName;
    }
}
