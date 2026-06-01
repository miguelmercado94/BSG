package com.bsg.soporterag.aplicacion.dto.request;

import lombok.Data;

@Data
public class CrearSoporteRequestDto {
    private String codigo;
    private String nombre;
    private String descripcion;
    private String urlRepo;
    private String nombreArchivo; // ej: "guia-instalacion.md"
    private String contenidoBase64;
}
