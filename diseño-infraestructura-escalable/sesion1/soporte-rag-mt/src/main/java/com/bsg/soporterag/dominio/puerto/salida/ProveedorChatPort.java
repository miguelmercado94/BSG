package com.bsg.soporterag.dominio.puerto.salida;

import com.bsg.soporterag.dominio.modelo.TipoTareaModelo;

public interface ProveedorChatPort {
    String chatearConContexto(String conversacionId, String mensajeUsuario, String contextoExtraido, TipoTareaModelo tipoTarea);
}
