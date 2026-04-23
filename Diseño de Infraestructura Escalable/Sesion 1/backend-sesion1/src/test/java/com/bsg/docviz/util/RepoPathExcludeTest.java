package com.bsg.docviz.util;

import org.junit.jupiter.api.Test;

import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

class RepoPathExcludeTest {

    @Test
    void excludesMavenTargetAndNodeModules() {
        assertTrue(RepoPathExclude.shouldExclude("pruebaJava/target/classes/Foo.class"));
        assertTrue(RepoPathExclude.shouldExclude("module/node_modules/pkg/foo.js"));
        assertFalse(RepoPathExclude.shouldExclude("pruebaJava/src/main/java/com/app/App.java"));
    }

    @Test
    void filterKeepsSources() {
        List<String> in = List.of(
                "pom.xml",
                "pruebaJava/target/x.class",
                "pruebaJava/src/main/java/Hello.java",
                "mvnw");
        List<String> out = RepoPathExclude.filterWorkspacePaths(in);
        assertEquals(List.of("pom.xml", "pruebaJava/src/main/java/Hello.java"), out);
    }
}
