package com.bsg.docviz.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * Chat RAG: historial en Firestore (mismo {@code userId} que {@code X-DocViz-User}) para multi‑turno.
 */
@ConfigurationProperties(prefix = "docviz.chat")
public class DocvizChatProperties {

    /**
     * Cuántos turnos previos (pregunta+respuesta guardados) incluir en el prompt. 0 = sin historial en el modelo.
     */
    private int historyMaxTurns = 12;

    /**
     * Límite de caracteres por respuesta previa al volcar al prompt (evita tokens enormes).
     */
    private int historyAnswerMaxChars = 2000;

    public int getHistoryMaxTurns() {
        return historyMaxTurns;
    }

    public void setHistoryMaxTurns(int historyMaxTurns) {
        this.historyMaxTurns = Math.max(0, Math.min(50, historyMaxTurns));
    }

    public int getHistoryAnswerMaxChars() {
        return historyAnswerMaxChars;
    }

    public void setHistoryAnswerMaxChars(int historyAnswerMaxChars) {
        int v = historyAnswerMaxChars;
        if (v < 200) {
            v = 200;
        } else if (v > 8000) {
            v = 8000;
        }
        this.historyAnswerMaxChars = v;
    }
}
