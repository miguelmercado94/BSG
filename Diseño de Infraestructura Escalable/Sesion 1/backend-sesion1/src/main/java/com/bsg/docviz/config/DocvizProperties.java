package com.bsg.docviz.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

import java.nio.file.Path;

@ConfigurationProperties(prefix = "docviz.context-masters")
public class DocvizProperties {

    private String basePath = "context-masters";

    public String getBasePath() {
        return basePath;
    }

    public void setBasePath(String basePath) {
        this.basePath = basePath;
    }

    public Path resolveRootDirectory() {
        return Path.of(basePath).toAbsolutePath().normalize();
    }
}
