package com.bsg.soporterag.aplicacion.dto.request;

import lombok.Data;

@Data
public class ActualizarRepositorioRequestDto {
    private String url;
    private String ramaPrincipal;
    private String descripcion;
    private java.util.List<String> tags;
}