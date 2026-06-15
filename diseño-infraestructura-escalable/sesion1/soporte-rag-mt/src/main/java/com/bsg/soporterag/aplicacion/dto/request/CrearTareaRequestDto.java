package com.bsg.soporterag.aplicacion.dto.request;

import lombok.Data;

@Data
public class CrearTareaRequestDto {
    private String codigoCelula;
    private String urlRepo;
    private String codigoUsuario;
    private String codigoTarea;
    private String titulo;
    private String enunciadoPrincipal;
}
