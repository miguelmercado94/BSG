package com.bsg.soporterag.infraestructura.adaptador.ia.model;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class ArchivoRamaDtoIa {
    private String path;
    private boolean existe;
    private CommitDtoIa ultimoCommit;
}
