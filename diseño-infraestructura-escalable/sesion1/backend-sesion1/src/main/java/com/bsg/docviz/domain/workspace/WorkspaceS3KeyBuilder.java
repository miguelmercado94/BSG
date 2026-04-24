package com.bsg.docviz.domain.workspace;

import com.bsg.docviz.config.DocvizWorkspaceS3Properties;
import org.springframework.stereotype.Component;

import java.nio.file.Paths;

/**
 * Claves S3 bajo {@code docviz.workspace-s3.*}: borradores y workarea por usuario y HU.
 * <p>
 * El borrador en disco sigue siendo {@code *_vN.ext.txt}; el <strong>objeto S3</strong> usa el mismo nombre que el
 * archivo versionado final ({@code *_vN.ext}) para que la UI y el bucket no muestren {@code .yml.txt}.
 */
@Component
public class WorkspaceS3KeyBuilder {

    private final DocvizWorkspaceS3Properties props;

    public WorkspaceS3KeyBuilder(DocvizWorkspaceS3Properties props) {
        this.props = props;
    }

    public static String segment(String s) {
        if (s == null || s.isBlank()) {
            return "_";
        }
        return s.trim().replaceAll("[^a-zA-Z0-9._-]", "_");
    }

    public String borradoresPrefix(String vectorNamespace, String taskHuCode, String userId) {
        return rootPrefix(vectorNamespace) + borradoresMiddle(taskHuCode, userId);
    }

    public String workareaPrefix(String vectorNamespace, String taskHuCode, String userId) {
        return rootPrefix(vectorNamespace) + workareaMiddle(taskHuCode, userId);
    }

    public String borradorKey(String vectorNamespace, String taskHuCode, String userId, String draftRelativePath) {
        String name = Paths.get(draftRelativePath.replace('\\', '/').trim()).getFileName().toString();
        return borradoresPrefix(vectorNamespace, taskHuCode, userId) + segment(borradorLeafNameForS3(name));
    }

    /**
     * Pasa de {@code foo_v2.yml.txt} (ruta del borrador en el clon) a {@code foo_v2.yml} (clave humana en S3).
     * Otros nombres se dejan igual para no romper claves arbitrarias.
     */
    static String borradorLeafNameForS3(String fileName) {
        if (fileName == null || fileName.isBlank()) {
            return "_";
        }
        String n = fileName.trim();
        if (n.endsWith(".txt") && n.matches("(?i).+_v\\d+\\..+\\.txt$")) {
            return n.substring(0, n.length() - 4);
        }
        return n;
    }

    public String workareaKey(String vectorNamespace, String taskHuCode, String userId, String acceptedRelativePath) {
        String name = Paths.get(acceptedRelativePath).getFileName().toString();
        return workareaPrefix(vectorNamespace, taskHuCode, userId) + segment(name);
    }

    private String rootPrefix(String vectorNamespace) {
        String t = props.getKeyRootTemplate();
        if (t == null || t.isBlank()) {
            return "";
        }
        String ns = vectorNamespace == null ? "" : vectorNamespace.trim().replaceAll("[^a-zA-Z0-9._-]", "_");
        return t.replace("{vectorNamespace}", ns);
    }

    private String borradoresMiddle(String taskHuCode, String userId) {
        return props.getBorradoresPrefixTemplate()
                .replace("{userId}", segment(userId))
                .replace("{taskCode}", segment(taskHuCode));
    }

    private String workareaMiddle(String taskHuCode, String userId) {
        return props.getWorkareaPrefixTemplate()
                .replace("{userId}", segment(userId))
                .replace("{taskCode}", segment(taskHuCode));
    }
}
