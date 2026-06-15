package com.bsg.soporterag.aplicacion.dto.response;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class ActualizarTagResponseDto {
    private String tagAnterior;
    private TagResponseDto tagActualizado;
}
