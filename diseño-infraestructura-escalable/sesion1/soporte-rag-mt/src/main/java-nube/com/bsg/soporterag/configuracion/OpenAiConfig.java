package com.bsg.soporterag.configuracion;

import org.springframework.ai.chat.model.ChatModel;
import org.springframework.ai.embedding.EmbeddingModel;
import org.springframework.ai.openai.OpenAiChatModel;
import org.springframework.ai.openai.OpenAiEmbeddingModel;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Primary;

@Configuration
public class OpenAiConfig {

    @Bean(name = "openAiChatModelPrimary")
    @Primary
    public ChatModel openAiChatModel(OpenAiChatModel openAiChatModel) {
        return openAiChatModel;
    }

    @Bean(name = "openAiEmbeddingModelPrimary")
    @Primary
    public EmbeddingModel openAiEmbeddingModel(OpenAiEmbeddingModel openAiEmbeddingModel) {
        return openAiEmbeddingModel;
    }
}