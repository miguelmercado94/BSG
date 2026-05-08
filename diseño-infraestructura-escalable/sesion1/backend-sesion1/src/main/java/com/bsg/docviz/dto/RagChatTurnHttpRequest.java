package com.bsg.docviz.dto;

import jakarta.validation.constraints.NotBlank;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonSetter;

/**
 * POST {@code /vector/chat/rag-turn}. El usuario se toma de la cabecera {@code X-DocViz-User}.
 */
@JsonIgnoreProperties(ignoreUnknown = true)
@JsonInclude(JsonInclude.Include.NON_EMPTY)
public class RagChatTurnHttpRequest {

    @NotBlank
    private String question;
    private String taskHuCode;
    private Long taskId;
    private String conversationId;
    private String cellName;

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

    public String getTaskHuCode() {
        return taskHuCode;
    }

    public void setTaskHuCode(String taskHuCode) {
        this.taskHuCode = taskHuCode;
    }

    public Long getTaskId() {
        return taskId;
    }

    public void setTaskId(Long taskId) {
        this.taskId = taskId;
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
