package com.bsg.soporterag.aplicacion.dto.request;

import lombok.Data;

@Data
public class ActualizarSoporteRequestDto {
    private String nombre;
    private String descripcion;
    private String nombreArchivo; // ej: "nueva-guia.md"
    private String contenidoBase64;
}
