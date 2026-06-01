package com.bsg.soporterag.configuracion;

import com.bsg.soporterag.dominio.puerto.salida.ProveedorChatPort;
import com.bsg.soporterag.dominio.puerto.salida.ProveedorEmbeddingPort;
import com.bsg.soporterag.infraestructura.adaptador.ia.SpringAiChatAdaptador;
import com.bsg.soporterag.infraestructura.adaptador.ia.SpringAiEmbeddingAdaptador;
import org.springframework.ai.chat.model.ChatModel;
import org.springframework.ai.chat.memory.ChatMemory;
import org.springframework.ai.chat.memory.MessageWindowChatMemory;
import org.springframework.ai.embedding.EmbeddingModel;
import org.springframework.ai.transformer.splitter.TokenTextSplitter;
import org.springframework.boot.autoconfigure.condition.ConditionalOnMissingBean;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Description;
import org.springframework.context.annotation.Configuration;

import java.util.List;
import java.util.function.Function;

@Configuration
public class IaConfiguracion {

    @Bean
    @ConditionalOnMissingBean(ProveedorEmbeddingPort.class)
    ProveedorEmbeddingPort proveedorEmbeddingPort(EmbeddingModel embeddingModel) {
        return new SpringAiEmbeddingAdaptador(embeddingModel);
    }

    @Bean
    @ConditionalOnMissingBean
    public TokenTextSplitter tokenTextSplitter(VectorPropiedades propiedades) {
        // Configuramos el chunker con los valores de application.yml (por defecto 800 tokens, 120 de solapamiento)
        return new TokenTextSplitter(
                propiedades.chunkSize(), 
                propiedades.chunkSize(), 
                propiedades.chunkOverlap(), 
                100, 
                true, 
                List.of('.', '?', '!', '\n')
        );
    }

    @Bean
    ChatMemory chatMemory() {
        // Memoria volátil temporal. Próximamente se implementará la persistencia en MongoDB.
        return MessageWindowChatMemory.builder().maxMessages(10).build();
    }

    @Bean
    @ConditionalOnMissingBean(ProveedorChatPort.class)
    ProveedorChatPort proveedorChatPort(ChatModel chatModel, ChatMemory chatMemory) {
        return new SpringAiChatAdaptador(chatModel, chatMemory);
    }

    @Bean
    @Description("Busca en la web información actualizada externa para responder consultas de soporte")
    public Function<String, String> webSearchTool() {
        // TODO: Integrar aquí la API real de búsqueda (ej. Google Search API, Tavily, etc.)
        return query -> "Resultados simulados de la web para la consulta: " + query;
    }
}
