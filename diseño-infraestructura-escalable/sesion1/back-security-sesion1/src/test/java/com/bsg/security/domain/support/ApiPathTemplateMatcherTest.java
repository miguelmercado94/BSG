package com.bsg.security.domain.support;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

class ApiPathTemplateMatcherTest {

    @Test
    void matches_singleId() {
        assertTrue(ApiPathTemplateMatcher.matches("/admin/cells/{id}", "/admin/cells/5"));
        assertFalse(ApiPathTemplateMatcher.matches("/admin/cells/{id}", "/admin/cells"));
    }

    @Test
    void matches_cellAndRepo() {
        assertTrue(
                ApiPathTemplateMatcher.matches(
                        "/admin/cells/{cellId}/repos/{repoId}", "/admin/cells/3/repos/10"));
    }

    @Test
    void literal_routes_not_confused_with_template() {
        assertFalse(ApiPathTemplateMatcher.matches("/admin/cells/{id}", "/admin/cells/hints/repo-url"));
        assertTrue(ApiPathTemplateMatcher.matches("/admin/cells/hints/repo-url", "/admin/cells/hints/repo-url"));
    }

    @Test
    void normalize_trailingSlash() {
        assertTrue(ApiPathTemplateMatcher.matches("/tags/", "/tags"));
    }
}
