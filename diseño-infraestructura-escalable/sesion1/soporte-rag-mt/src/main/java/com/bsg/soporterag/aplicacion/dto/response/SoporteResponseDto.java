package com.bsg.soporterag.aplicacion.dto.response;

import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.Data;

@Data
@JsonInclude(JsonInclude.Include.NON_NULL)
public class SoporteResponseDto {
    private String codigo;
    private String nombre;
    private String descripcion;
    private String urlRepo;
    private String urlS3;
    private String contenidoBase64;
}
