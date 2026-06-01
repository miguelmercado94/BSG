package com.bsg.soporterag.dominio.modelo;

import lombok.Data;
import java.util.HashSet;
import java.util.Set;

@Data
public class Celula {
    private String id;
    private String codigo;
    private String nombre;
    private String descripcion;
    private Set<Repositorio> repositorios = new HashSet<>();
}