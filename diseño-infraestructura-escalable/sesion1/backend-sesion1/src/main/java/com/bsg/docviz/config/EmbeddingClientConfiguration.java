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
 * Embeddings por defecto: Spring AI + Ollama ({@link EmbeddingModel}). Almacén pgvector no usa Pinecone.
 * Solo si {@code docviz.vector.embeddings-provider=pinecone-inference} se usa la API HTTP de inferencia Pinecone
 * (requiere {@code PINECONE_API_KEY}).
 */
@Configuration
public class EmbeddingClientConfiguration {

    /** Evita {@code @ConditionalOnBean(EmbeddingModel)}: se evalúa antes que la auto-config de Ollama. */
    @Bean
    @Primary
    @ConditionalOnProperty(prefix = "docviz.vector", name = "embeddings-provider", havingValue = "spring-ollama", matchIfMissing = true)
    public EmbeddingClient springAiEmbeddingClient(EmbeddingModel embeddingModel) {
        return new SpringAiEmbeddingClient(embeddingModel);
    }

    @Bean
    @ConditionalOnMissingBean(EmbeddingClient.class)
    @ConditionalOnProperty(prefix = "docviz.vector", name = "embeddings-provider", havingValue = "pinecone-inference")
    public EmbeddingClient pineconeInferenceEmbeddingClient(VectorProperties vectorProperties) {
        return new PineconeInferenceEmbeddingClient(vectorProperties);
    }
}
