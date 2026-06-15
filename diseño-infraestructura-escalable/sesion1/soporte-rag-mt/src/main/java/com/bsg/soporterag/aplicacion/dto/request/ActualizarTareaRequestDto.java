package com.bsg.soporterag.aplicacion.dto.request;

import lombok.Data;

@Data
public class ActualizarTareaRequestDto {
    private String titulo;
    private String urlRepo;
    private String enunciadoPrincipal;
}
