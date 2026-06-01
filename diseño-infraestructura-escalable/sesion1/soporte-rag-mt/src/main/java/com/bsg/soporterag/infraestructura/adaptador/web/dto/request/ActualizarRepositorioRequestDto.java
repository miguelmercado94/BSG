package com.bsg.soporterag.infraestructura.adaptador.web.dto.request;

import lombok.Data;

@Data
public class ActualizarRepositorioRequestDto {
    private String url;
    private String ramaPrincipal;
    private String descripcion;
}