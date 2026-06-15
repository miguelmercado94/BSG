package com.bsg.soporterag.infraestructura.adaptador.ia.model;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class CommitDtoIa {
    private String hash;
    private String mensaje;
    private String autor;
}
