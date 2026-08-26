package com.bsg.soporterag.infraestructura.adaptador.ia;

import com.bsg.soporterag.configuracion.ChatPropiedades;
import com.bsg.soporterag.configuracion.PromptsPropiedades;
import com.bsg.soporterag.dominio.modelo.TipoTareaModelo;
import com.bsg.soporterag.dominio.puerto.salida.ProveedorChatPort;
import org.springframework.ai.chat.client.ChatClient;
import org.springframework.ai.chat.model.ChatModel;
import org.springframework.ai.chat.prompt.DefaultChatOptions;
import reactor.core.publisher.Flux;

public class SpringAiChatAdaptador implements ProveedorChatPort {

    private final ChatClient chatClient;
    private final PromptsPropiedades prompts;
    private final ChatPropiedades chatPropiedades;

    public SpringAiChatAdaptador(ChatModel chatModel, PromptsPropiedades prompts, ChatPropiedades chatPropiedades) {
        this.chatClient = ChatClient.builder(chatModel).build();
        this.prompts = prompts;
        this.chatPropiedades = chatPropiedades;
    }

    @Override
    public String chatearConContexto(String conversacionId, String mensajeUsuario, String contextoExtraido, TipoTareaModelo tipoTarea) {
        DefaultChatOptions options = new DefaultChatOptions();
        String modeloEspecifico = resolverModelo(tipoTarea);
        if (modeloEspecifico != null) {
            options.setModel(modeloEspecifico);
        }

        // Para ANALIZAR y RESUMIR no se necesitan tools (solo para RESPONDER)
        var spec = this.chatClient.prompt()
                .options(options)
                .system(prompts.sistema())
                .user(userSpec -> userSpec.text(prompts.usuario())
                        .param("contexto", contextoExtraido)
                        .param("pregunta", mensajeUsuario));

        if (tipoTarea == TipoTareaModelo.RESPONDER) {
            spec = spec.toolNames("consultarPaginaWeb");
        }

        return spec.call().content();
    }

    @Override
    public Flux<String> chatearConContextoStream(String conversacionId, String mensajeUsuario, String contextoExtraido, TipoTareaModelo tipoTarea) {
        DefaultChatOptions options = new DefaultChatOptions();
        String modeloEspecifico = resolverModelo(tipoTarea);
        if (modeloEspecifico != null) {
            options.setModel(modeloEspecifico);
        }

        // Usar el método blocking con tools para RESPONDER (soporta tool calling)
        // Emitir la respuesta completa en chunks simulados para mantener la interfaz SSE
        if (tipoTarea == TipoTareaModelo.RESPONDER) {
            return Flux.defer(() -> {
                String respuesta = this.chatClient.prompt()
                        .options(options)
                        .system(prompts.sistema())
                        .user(userSpec -> userSpec.text(prompts.usuario())
                                .param("contexto", contextoExtraido)
                                .param("pregunta", mensajeUsuario))
                        .toolNames("consultarPaginaWeb", "obtenerContenidoArchivo", "procesarPropuestaModificacion")
                        .call()
                        .content();
                // Emitir en chunks de ~100 chars para efecto de streaming
                if (respuesta == null || respuesta.isEmpty()) return Flux.<String>empty();
                int chunkSize = 100;
                return Flux.<String, Integer>generate(
                        () -> 0,
                        (idx, sink) -> {
                            int start = idx * chunkSize;
                            if (start >= respuesta.length()) {
                                sink.complete();
                            } else {
                                int end = Math.min(start + chunkSize, respuesta.length());
                                sink.next(respuesta.substring(start, end));
                            }
                            return idx + 1;
                        }
                );
            }).subscribeOn(reactor.core.scheduler.Schedulers.boundedElastic());
        }

        // Para otros tipos (analizar, resumir) — stream real sin tools
        return this.chatClient.prompt()
                .options(options)
                .system(prompts.sistema())
                .user(userSpec -> userSpec.text(prompts.usuario())
                        .param("contexto", contextoExtraido)
                        .param("pregunta", mensajeUsuario))
                .stream()
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
