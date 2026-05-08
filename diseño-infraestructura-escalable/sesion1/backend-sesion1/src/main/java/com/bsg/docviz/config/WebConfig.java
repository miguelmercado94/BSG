package com.bsg.docviz.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.AsyncSupportConfigurer;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
public class WebConfig {

    /**
     * Sin esto, POST /vector/ingest/stream cae en AsyncRequestTimeoutException (~30s por defecto)
     * mientras la ingesta a Pinecone sigue activa.
     */
    @Bean
    public WebMvcConfigurer asyncRequestTimeoutConfigurer() {
        return new WebMvcConfigurer() {
            @Override
            public void configureAsyncSupport(AsyncSupportConfigurer configurer) {
                configurer.setDefaultTimeout(0L);
            }
        };
    }

    @Bean
    public WebMvcConfigurer corsConfigurer() {
        return new WebMvcConfigurer() {
            @Override
            public void addCorsMappings(CorsRegistry registry) {
                registry.addMapping("/**")
                        .allowedOrigins(
                                // Explícito por si el matcheo por patrón falla en proxies OPTIONS.
                                "http://bsg-frontend-alb-1943066260.us-east-1.elb.amazonaws.com",
                                "https://bsg-frontend-alb-1943066260.us-east-1.elb.amazonaws.com")
                        .allowedOriginPatterns(
                                "http://localhost:*",
                                "http://127.0.0.1:*",
                                "http://*.us-east-1.elb.amazonaws.com",
                                "https://*.us-east-1.elb.amazonaws.com",
                                "https://*.up.railway.app")
                        .allowedMethods("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS")
                        .allowedHeaders("*")
                        .exposedHeaders("X-DocViz-Resolved-Conversation-Id")
                        .allowCredentials(true);
            }
        };
    }
}
