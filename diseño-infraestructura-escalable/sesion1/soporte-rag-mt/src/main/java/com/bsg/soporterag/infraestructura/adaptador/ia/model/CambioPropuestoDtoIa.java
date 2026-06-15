package com.bsg.soporterag.infraestructura.adaptador.ia.model;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class CambioPropuestoDtoIa implements Comparable<CambioPropuestoDtoIa> {
    private int lineaInicial;
    private int lineaFinal;
    private TipoOperacionArchivo operacion;
    private List<String> nuevasLineas;

    @Override
    public int compareTo(CambioPropuestoDtoIa otro) {
        // Orden descendente por lineaInicial (de mayor a menor)
        // Esto es crucial para aplicar los cambios desde abajo hacia arriba
        // y no alterar los índices de línea para los cambios superiores.
        return Integer.compare(otro.lineaInicial, this.lineaInicial);
    }
}
