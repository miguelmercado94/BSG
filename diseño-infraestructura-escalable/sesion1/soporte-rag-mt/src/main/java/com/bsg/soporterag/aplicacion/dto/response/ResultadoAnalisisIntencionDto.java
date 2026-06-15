package com.bsg.soporterag.aplicacion.dto.response;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class ResultadoAnalisisIntencionDto {
    private boolean requiereProcesamientoProfundo;
    private String mensajeOriginal;
    private boolean requiereRag;
    private boolean requiereHistorialChat;
    private List<String> urlsToolsRequeridas; // URLs o nombres de las herramientas específicas a usar
}
