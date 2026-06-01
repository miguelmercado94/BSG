package com.bsg.soporterag.aplicacion.dto.response;

import lombok.Data;
import java.util.Set;

@Data
public class CelulaResponseDto {
    private String codigo;
    private String nombre;
    private String descripcion;
    private Set<RepositorioResponseDto> repositorios;
}