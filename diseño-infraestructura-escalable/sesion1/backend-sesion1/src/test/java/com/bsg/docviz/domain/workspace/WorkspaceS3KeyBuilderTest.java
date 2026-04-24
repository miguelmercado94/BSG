package com.bsg.docviz.domain.workspace;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;

class WorkspaceS3KeyBuilderTest {

    @Test
    void borradorLeafStripsTxtForVersionedDraft() {
        assertEquals("docker-compose_v2.yml", WorkspaceS3KeyBuilder.borradorLeafNameForS3("docker-compose_v2.yml.txt"));
    }

    @Test
    void borradorLeafLeavesPlainTxt() {
        assertEquals("readme.txt", WorkspaceS3KeyBuilder.borradorLeafNameForS3("readme.txt"));
    }
}
