package com.bsg.soporterag.aplicacion.dto.request;

import lombok.Data;

@Data
public class RepositorioRequestDto {
    private String nombre;
    private String url;
    private String ramaPrincipal;
    private String descripcion;
    private String codigoCelula;
}