package com.bsg.docviz.util;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;

class WorkAreaDraftPathBuilderTest {

    @Test
    void rule_stem_ext_to_stem_vN_ext_txt() {
        assertEquals(
                "findu/docker-compose_v1.yml.txt",
                WorkAreaDraftPathBuilder.buildDraftTxtPath("findu/docker-compose.yml", 1));
        assertEquals("pom_v2.xml.txt", WorkAreaDraftPathBuilder.buildDraftTxtPath("pom.xml", 2));
        // extensión real .java, no un sufijo literal "ext"
        assertEquals("archivo_v1.java.txt", WorkAreaDraftPathBuilder.buildDraftTxtPath("archivo.java", 1));
        assertEquals("src/archivo_v1.java.txt", WorkAreaDraftPathBuilder.buildDraftTxtPath("src/archivo.java", 1));
    }

    @Test
    void sanitize_then_same_rule() {
        assertEquals(
                "findu/docker-compose_v1.yml.txt",
                WorkAreaDraftPathBuilder.buildDraftTxtPath("findu/docker-compose.yml_v1", 1));
        assertEquals(
                "findu/docker-compose_v1.yml.txt",
                WorkAreaDraftPathBuilder.buildDraftTxtPath("findu/docker-compose.yml_V1", 1));
    }

    @Test
    void sanitizeFileNameLikeOriginalInRepo() {
        assertEquals("docker-compose.yml", WorkAreaDraftPathBuilder.sanitizeFileNameLikeOriginalInRepo("docker-compose.yml_v1"));
        assertEquals("docker-compose.yml", WorkAreaDraftPathBuilder.sanitizeFileNameLikeOriginalInRepo("docker-compose.yml_V1"));
        assertEquals("pom_v1.xml", WorkAreaDraftPathBuilder.sanitizeFileNameLikeOriginalInRepo("pom_v1.xml"));
        assertEquals("foo.bar", WorkAreaDraftPathBuilder.sanitizeFileNameLikeOriginalInRepo("foo.bar"));
    }

    @Test
    void normalizeSourceRelativePath() {
        assertEquals(
                "findu/docker-compose.yml",
                WorkAreaDraftPathBuilder.normalizeSourceRelativePath("findu/docker-compose.yml_V1"));
    }
}
