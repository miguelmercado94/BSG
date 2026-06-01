package com.bsg.soporterag.aplicacion.dto.response;

import lombok.Data;

@Data
public class IndexacionArchivoResponseDto {
    private String filePath;
    private boolean exitoso;
    private String mensaje;
}
