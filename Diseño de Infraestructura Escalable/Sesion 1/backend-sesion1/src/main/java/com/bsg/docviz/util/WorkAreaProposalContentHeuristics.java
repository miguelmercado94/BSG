package com.bsg.docviz.util;

/**
 * Decide si el campo {@code content} del LLM parece un archivo completo (p. ej. docker-compose) o un resumen inválido.
 */
public final class WorkAreaProposalContentHeuristics {

    private WorkAreaProposalContentHeuristics() {}

    /**
     * Priorizar {@code content} frente a {@code changeBlocks} cuando el modelo envió el archivo entero bien formado.
     */
    public static boolean shouldPreferFullFileContent(String content, String originalSanitized) {
        if (content == null || content.isBlank()) {
            return false;
        }
        if (looksLikeInvalidYamlStub(content, originalSanitized)) {
            return false;
        }
        int cl = content.length();
        int ol = Math.max(originalSanitized != null ? originalSanitized.length() : 0, 1);
        if (cl >= ol * 0.22 && cl >= 280) {
            return true;
        }
        long propLines = content.lines().count();
        if (content.contains("services:") && propLines >= 14) {
            return true;
        }
        if (content.contains("image:") && content.contains("services:") && propLines >= 10) {
            return true;
        }
        return false;
    }

    /**
     * Detecta respuestas inválidas tipo {@code ---\nservices:\n- postgres\n- foo} sin claves de servicio reales.
     */
    public static boolean looksLikeInvalidYamlStub(String content, String originalSanitized) {
        if (content == null || content.isBlank()) {
            return false;
        }
        long origLines =
                originalSanitized == null || originalSanitized.isEmpty()
                        ? 0
                        : originalSanitized.lines().count();
        long propLines = content.lines().count();
        boolean shortVsOriginal = origLines > 35 && propLines < 18;
        boolean noServiceDefinition = !content.contains("image:")
                && !content.contains("build:")
                && content.contains("services:");
        if (shortVsOriginal && noServiceDefinition) {
            return true;
        }
        String trim = content.trim();
        if (trim.startsWith("---") && propLines < 22 && !content.contains("image:")) {
            return true;
        }
        if (propLines <= 12
                && content.contains("services:")
                && !content.contains("environment:")
                && !content.contains("image:")
                && origLines > 40) {
            return true;
        }
        return false;
    }
}
