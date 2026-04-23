package com.bsg.docviz.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

import java.nio.file.Path;

@ConfigurationProperties(prefix = "docviz.context-masters")
public class DocvizProperties {

    private String basePath = "context-masters";

    /**
     * Ruta al ejecutable {@code git}. Vacío → {@code "git"} vía PATH.
     * En Alpine/Linux suele ser {@code /usr/bin/git} si el proceso Java no hereda un PATH completo.
     */
    private String gitExecutable = "";

    public String getBasePath() {
        return basePath;
    }

    public void setBasePath(String basePath) {
        this.basePath = basePath;
    }

    public String getGitExecutable() {
        return gitExecutable;
    }

    public void setGitExecutable(String gitExecutable) {
        this.gitExecutable = gitExecutable == null ? "" : gitExecutable;
    }

    public Path resolveRootDirectory() {
        return Path.of(basePath).toAbsolutePath().normalize();
    }
}
