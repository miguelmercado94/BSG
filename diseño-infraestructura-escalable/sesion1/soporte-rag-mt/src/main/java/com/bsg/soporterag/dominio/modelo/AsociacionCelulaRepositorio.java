package com.bsg.soporterag.dominio.modelo;

import lombok.Data;
import lombok.AllArgsConstructor;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class AsociacionCelulaRepositorio {
    private String id;
    private String codigoCelula;
    private String nombreRepo;
}