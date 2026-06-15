package com.bsg.soporterag.infraestructura.adaptador.ia.model;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class ConsultaRamasResponseDtoIa {
    private List<RamaDtoIa> ramas;
}
