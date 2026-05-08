package com.bsg.docviz.config;

import com.bsg.docviz.vector.EmbeddingClient;
import com.bsg.docviz.vector.PineconeInferenceEmbeddingClient;
import com.bsg.docviz.vector.SpringAiEmbeddingClient;
import org.springframework.ai.embedding.EmbeddingModel;
import org.springframework.boot.autoconfigure.condition.ConditionalOnMissingBean;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Primary;

/**
 * Embeddings vía Spring AI {@link EmbeddingModel}. La dependencia explícita en {@link EmbeddingModel}
 * fuerza el orden correcto respecto a la auto-config (OpenAI/Ollama); no usar
 * {@code @ConditionalOnBean(EmbeddingModel)} en el método (se evalúa antes que exista el bean).
 */
@Configuration
public class EmbeddingClientConfiguration {

    @Bean
    @Primary
    @ConditionalOnMissingBean(EmbeddingClient.class)
    @ConditionalOnProperty(prefix = "docviz.vector", name = "embeddings-provider", havingValue = "spring-ollama", matchIfMissing = true)
    public EmbeddingClient springAiEmbeddingClientOllama(EmbeddingModel embeddingModel) {
        return new SpringAiEmbeddingClient(embeddingModel);
    }

    @Bean
    @Primary
    @ConditionalOnMissingBean(EmbeddingClient.class)
    @ConditionalOnProperty(prefix = "docviz.vector", name = "embeddings-provider", havingValue = "spring-ai")
    public EmbeddingClient springAiEmbeddingClientOpenAi(EmbeddingModel embeddingModel) {
        return new SpringAiEmbeddingClient(embeddingModel);
    }

    @Bean
    @ConditionalOnMissingBean(EmbeddingClient.class)
    @ConditionalOnProperty(prefix = "docviz.vector", name = "embeddings-provider", havingValue = "pinecone-inference")
    public EmbeddingClient pineconeInferenceEmbeddingClient(VectorProperties vectorProperties) {
        return new PineconeInferenceEmbeddingClient(vectorProperties);
    }
}
