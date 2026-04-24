package com.bsg.docviz.dto;

import com.fasterxml.jackson.annotation.JsonInclude;

import java.util.List;

/** Bloque de edición proveniente del YAML de propuestas del modelo (líneas 1-based en el archivo base). */
@JsonInclude(JsonInclude.Include.NON_NULL)
public class WorkAreaYamlProposalBlockDto {

    private int start;
    private int end;
    /** REPLACE | NEW | DELETE (mayúsculas o minúsculas). */
    private String type;
    private List<String> lines;

    public int getStart() {
        return start;
    }

    public void setStart(int start) {
        this.start = start;
    }

    public int getEnd() {
        return end;
    }

    public void setEnd(int end) {
        this.end = end;
    }

    public String getType() {
        return type;
    }

    public void setType(String type) {
        this.type = type;
    }

    public List<String> getLines() {
        return lines;
    }

    public void setLines(List<String> lines) {
        this.lines = lines;
    }
}
