package com.bsg.docviz;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.ConfigurationPropertiesScan;

@SpringBootApplication
@ConfigurationPropertiesScan(basePackages = "com.bsg.docviz.config")
public class DocumentContextVisualizerApplication {

    public static void main(String[] args) {
        SpringApplication.run(DocumentContextVisualizerApplication.class, args);
    }
}
