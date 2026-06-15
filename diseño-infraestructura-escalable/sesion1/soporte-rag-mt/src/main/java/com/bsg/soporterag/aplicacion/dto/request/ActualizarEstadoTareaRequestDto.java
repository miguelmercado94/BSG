package com.bsg.soporterag.aplicacion.dto.request;

import com.bsg.soporterag.dominio.modelo.EstadoTarea;
import lombok.Data;

@Data
public class ActualizarEstadoTareaRequestDto {
    private EstadoTarea nuevoEstado;
}
