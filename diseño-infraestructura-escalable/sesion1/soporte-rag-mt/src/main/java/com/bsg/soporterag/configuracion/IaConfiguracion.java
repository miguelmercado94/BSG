package com.bsg.soporterag.configuracion;

import com.bsg.soporterag.dominio.puerto.salida.ProveedorChatPort;
import com.bsg.soporterag.dominio.puerto.salida.ProveedorEmbeddingPort;
import com.bsg.soporterag.infraestructura.adaptador.ia.SpringAiChatAdaptador;
import com.bsg.soporterag.infraestructura.adaptador.ia.SpringAiEmbeddingAdaptador;
import com.bsg.soporterag.infraestructura.adaptador.ia.herramientas.HerramientasChat;
import org.springframework.ai.chat.model.ChatModel;
import org.springframework.ai.embedding.EmbeddingModel;
import org.springframework.ai.tool.ToolCallbackProvider;
import org.springframework.ai.tool.method.MethodToolCallbackProvider;
import org.springframework.boot.autoconfigure.condition.ConditionalOnMissingBean;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class IaConfiguracion {

    @Bean
    @ConditionalOnMissingBean(ProveedorEmbeddingPort.class)
    ProveedorEmbeddingPort proveedorEmbeddingPort(EmbeddingModel embeddingModel) {
        return new SpringAiEmbeddingAdaptador(embeddingModel);
    }

    @Bean
    @ConditionalOnMissingBean(ProveedorChatPort.class)
    ProveedorChatPort proveedorChatPort(ChatModel chatModel, PromptsPropiedades prompts, ChatPropiedades chatPropiedades, HerramientasChat herramientasChat) {
        return new SpringAiChatAdaptador(chatModel, prompts, chatPropiedades, herramientasChat);
    }

    @Bean
    ToolCallbackProvider herramientasChatToolCallbackProvider(HerramientasChat herramientasChat) {
        return MethodToolCallbackProvider.builder()
                .toolObjects(herramientasChat)
                .build();
    }
}
