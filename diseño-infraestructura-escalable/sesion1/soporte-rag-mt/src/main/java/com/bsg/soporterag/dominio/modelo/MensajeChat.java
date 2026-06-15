package com.bsg.soporterag.dominio.modelo;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.Instant;
import java.time.LocalDate;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class MensajeChat {
    private String textoEntrada;
    private String textoFormateado;
    private String textoRespuesta;
    private LocalDate fechaRespuesta;
    private Instant horaRespuesta;
}
