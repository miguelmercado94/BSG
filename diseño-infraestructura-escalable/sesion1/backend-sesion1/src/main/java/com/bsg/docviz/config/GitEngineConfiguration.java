package com.bsg.docviz.config;

import com.bsg.docviz.git.GitEngine;
import com.bsg.docviz.git.JGitGitEngine;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class GitEngineConfiguration {

    @Bean
    public GitEngine gitEngine() {
        return new JGitGitEngine();
    }
}
