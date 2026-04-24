package com.bsg.docviz.support;

import com.bsg.docviz.config.DocvizSupportProperties;
import com.bsg.docviz.repository.CellRepoEntity;
import org.springframework.stereotype.Component;

/**
 * Construye prefijos S3 para Markdown de soporte en el bucket {@code soporte}:
 * {@code {repoSlug}/{archivo}.{ext}} o sesión {@code _session/…}.
 */
@Component
public class SupportS3PathBuilder {

    private final DocvizSupportProperties props;

    public SupportS3PathBuilder(DocvizSupportProperties props) {
        this.props = props;
    }

    public String cellRepoSupportPrefix(CellRepoEntity repo) {
        String slug = slugSegment(repo.displayName(), "repo");
        return expandRepo(props.getSupportRepoPrefixTemplate(), slug);
    }

    public String sessionSupportPrefix(String rawVectorNamespace) {
        String t = props.getSupportSessionPrefixTemplate();
        if (t == null || t.isBlank()) {
            return "_session/";
        }
        if (rawVectorNamespace == null || rawVectorNamespace.isBlank()) {
            return t.contains("{vectorNamespace}") ? t.replace("{vectorNamespace}", "_") : t;
        }
        String ns = rawVectorNamespace.trim().replaceAll("[^a-zA-Z0-9._-]", "_");
        return t.replace("{vectorNamespace}", ns);
    }

    private static String expandRepo(String template, String repoSlug) {
        return template.replace("{repoSlug}", repoSlug);
    }

    private static String slugSegment(String raw, String fallback) {
        if (raw == null || raw.isBlank()) {
            return fallback;
        }
        String t = raw.trim().replaceAll("[^a-zA-Z0-9._-]+", "_");
        return t.isBlank() ? fallback : t;
    }
}
