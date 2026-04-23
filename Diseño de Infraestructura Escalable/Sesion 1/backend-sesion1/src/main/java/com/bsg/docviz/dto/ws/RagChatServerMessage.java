package com.bsg.docviz.dto.ws;

import com.bsg.docviz.dto.WorkAreaProposalItemDto;
import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonProperty;

import java.util.List;

/**
 * Mensajes salientes hacia el cliente WebSocket (tipados; Jackson serializa a JSON).
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
public final class RagChatServerMessage {

    private RagChatServerMessage() {}

    public record Delta(
            @JsonProperty("type") String type,
            @JsonProperty("text") String text) {
        public static Delta of(String text) {
            return new Delta("delta", text);
        }
    }

    public record Start(
            @JsonProperty("type") String type,
            @JsonProperty("sources") List<String> sources) {
        public static Start of(List<String> sources) {
            return new Start("start", sources);
        }
    }

    public record Error(
            @JsonProperty("type") String type,
            @JsonProperty("message") String message) {
        public static Error of(String message) {
            return new Error("error", message);
        }
    }

    public record Done(@JsonProperty("type") String type) {
        public static Done instance() {
            return new Done("done");
        }
    }

    public record Proposals(
            @JsonProperty("type") String type,
            @JsonProperty("proposals") List<WorkAreaProposalItemDto> proposals) {
        public static Proposals of(List<WorkAreaProposalItemDto> proposals) {
            return new Proposals("proposals", proposals);
        }
    }
}
