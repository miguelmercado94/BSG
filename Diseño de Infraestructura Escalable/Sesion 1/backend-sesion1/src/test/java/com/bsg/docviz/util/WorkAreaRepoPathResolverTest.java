package com.bsg.docviz.util;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;

class WorkAreaRepoPathResolverTest {

    @Test
    void stripsRootFolderPrefix() {
        assertEquals("docker-compose.yml", WorkAreaRepoPathResolver.stripUiRootFolderPrefix("findu/docker-compose.yml", "findu"));
    }

    @Test
    void noPrefixUnchanged() {
        assertEquals("src/App.java", WorkAreaRepoPathResolver.stripUiRootFolderPrefix("src/App.java", "findu"));
    }

    @Test
    void blankLabelNoop() {
        assertEquals("findu/x.txt", WorkAreaRepoPathResolver.stripUiRootFolderPrefix("findu/x.txt", ""));
    }
}
