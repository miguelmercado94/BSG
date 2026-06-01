package com.bsg.soporterag.aplicacion.dto.request;

import lombok.Data;

@Data
public class IndexarArchivoRequestDto {
    private String urlRepo;
    private String filePath;
    private String contenidoBase64;
}
