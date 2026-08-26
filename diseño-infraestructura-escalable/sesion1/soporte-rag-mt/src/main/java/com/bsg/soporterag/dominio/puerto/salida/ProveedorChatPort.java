package com.bsg.soporterag.dominio.puerto.salida;

import com.bsg.soporterag.dominio.modelo.TipoTareaModelo;
import reactor.core.publisher.Flux;

public interface ProveedorChatPort {
    String chatearConContexto(String conversacionId, String mensajeUsuario, String contextoExtraido, TipoTareaModelo tipoTarea);

    /**
     * Streaming de tokens desde el LLM. Cada elemento del Flux es un fragmento de texto.
     */
    Flux<String> chatearConContextoStream(String conversacionId, String mensajeUsuario, String contextoExtraido, TipoTareaModelo tipoTarea);
}
