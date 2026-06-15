package com.bsg.soporterag.infraestructura.adaptador.ia.model;

import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
@JsonInclude(JsonInclude.Include.NON_NULL)
public class RamaDtoIa {
    private String nombre;
    private CommitDtoIa ultimoCommit;
    private List<ArchivoRamaDtoIa> archivos;
}
