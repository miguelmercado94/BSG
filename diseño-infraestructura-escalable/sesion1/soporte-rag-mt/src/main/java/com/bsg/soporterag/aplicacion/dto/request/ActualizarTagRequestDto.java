package com.bsg.soporterag.aplicacion.dto.request;

import lombok.Data;

@Data
public class ActualizarTagRequestDto {
    private String nuevoNombreTag;
    private String descripcionTag;
    private Boolean habilitado;
}
