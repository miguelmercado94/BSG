package com.bsg.soporterag.infraestructura.adaptador.ia;

import com.bsg.soporterag.configuracion.ChatPropiedades;
import com.bsg.soporterag.configuracion.PromptsPropiedades;
import com.bsg.soporterag.dominio.modelo.TipoTareaModelo;
import com.bsg.soporterag.dominio.puerto.salida.ProveedorChatPort;
import org.springframework.ai.chat.client.ChatClient;
import org.springframework.ai.chat.model.ChatModel;
import org.springframework.ai.chat.prompt.DefaultChatOptions;

public class SpringAiChatAdaptador implements ProveedorChatPort {

    private final ChatClient chatClient;
    private final PromptsPropiedades prompts;
    private final ChatPropiedades chatPropiedades;

    public SpringAiChatAdaptador(ChatModel chatModel, PromptsPropiedades prompts, ChatPropiedades chatPropiedades) {
        // Al usar build(), Spring AI auto-registra las herramientas (@Tool) si están disponibles en el contexto.
        this.chatClient = ChatClient.builder(chatModel).build();
        this.prompts = prompts;
        this.chatPropiedades = chatPropiedades;
    }

    @Override
    public String chatearConContexto(String conversacionId, String mensajeUsuario, String contextoExtraido, TipoTareaModelo tipoTarea) {
        
        String modeloEspecifico = resolverModelo(tipoTarea);

        DefaultChatOptions options = new DefaultChatOptions();
        if (modeloEspecifico != null) {
            options.setModel(modeloEspecifico);
        }

        return this.chatClient.prompt()
                .options(options)
                .system(prompts.sistema())
                .user(userSpec -> userSpec.text(prompts.usuario())
                        .param("contexto", contextoExtraido)
                        .param("pregunta", mensajeUsuario))
                // Eliminamos MessageChatMemoryAdvisor porque el historial ahora lo gestiona explícitamente el Caso de Uso (Rolling Summary)
                // Registramos todas las herramientas disponibles. El LLM decidirá cuál usar basándose en las instrucciones del contexto.
                .toolNames("consultarPaginaWeb", "consultarRamasRepositorio", "obtenerContenidoArchivo", "procesarPropuestaModificacion")
                .call()
                .content();
    }

    private String resolverModelo(TipoTareaModelo tipoTarea) {
        if (chatPropiedades.models() == null) {
            return null;
        }
        return switch (tipoTarea) {
            case ANALIZAR -> chatPropiedades.models().getOrDefault("analizar", null);
            case RESUMIR -> chatPropiedades.models().getOrDefault("resumir", null);
            case RESPONDER -> chatPropiedades.models().getOrDefault("responder", null);
        };
    }
}
