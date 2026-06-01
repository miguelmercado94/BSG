package com.bsg.soporterag.aplicacion.dto.response;

import lombok.Data;

import java.util.List;
import java.util.Map;

@Data
public class IndexacionCompletaResponseDto {
    private RepositorioResponseDto repositorio;
    private List<String> archivosIndexados;
    private Map<String, String> archivosFallidos;
}
