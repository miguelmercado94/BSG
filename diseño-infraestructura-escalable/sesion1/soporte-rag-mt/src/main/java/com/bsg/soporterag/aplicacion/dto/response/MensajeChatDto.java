package com.bsg.soporterag.aplicacion.dto.response;

import lombok.Data;

import java.time.Instant;
import java.time.LocalDate;

@Data
public class MensajeChatDto {
    private String textoEntrada;
    private String textoFormateado;
    private String textoRespuesta;
    private LocalDate fechaRespuesta;
    private Instant horaRespuesta;
}
