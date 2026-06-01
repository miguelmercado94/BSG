package com.bsg.soporterag.dominio.puerto.salida;

public interface ProveedorChatPort {
    String chatearConContexto(String conversacionId, String mensajeUsuario, String contextoExtraido);
}