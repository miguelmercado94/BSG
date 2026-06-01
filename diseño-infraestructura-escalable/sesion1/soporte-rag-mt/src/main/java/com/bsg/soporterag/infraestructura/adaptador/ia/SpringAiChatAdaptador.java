package com.bsg.soporterag.infraestructura.adaptador.ia;

import com.bsg.soporterag.dominio.puerto.salida.ProveedorChatPort;
import org.springframework.ai.chat.client.ChatClient;
import org.springframework.ai.chat.client.advisor.MessageChatMemoryAdvisor;
import org.springframework.ai.chat.memory.ChatMemory;
import org.springframework.ai.chat.model.ChatModel;

public class SpringAiChatAdaptador implements ProveedorChatPort {

    private final ChatClient chatClient;
    private final ChatMemory chatMemory;

    public SpringAiChatAdaptador(ChatModel chatModel, ChatMemory chatMemory) {
        // Envolvemos el ChatModel en un ChatClient para aprovechar su API fluida (Advisors y Tools)
        this.chatClient = ChatClient.builder(chatModel).build();
        this.chatMemory = chatMemory;
    }

    @Override
    public String chatearConContexto(String conversacionId, String mensajeUsuario, String contextoExtraido) {
        return this.chatClient.prompt()
                .system(sys -> sys.text("Eres un asistente de soporte. Usa este contexto para guiarte: {contexto}")
                        .param("contexto", contextoExtraido))
                .user(mensajeUsuario)
                .advisors(MessageChatMemoryAdvisor.builder(this.chatMemory)
                        .conversationId(conversacionId)
                        .build())
                .toolNames("webSearchTool")
                .call()
                .content();
    }
}