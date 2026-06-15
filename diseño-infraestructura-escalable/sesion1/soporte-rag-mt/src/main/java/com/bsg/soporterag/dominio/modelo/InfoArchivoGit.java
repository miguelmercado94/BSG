package com.bsg.soporterag.dominio.modelo;

public record InfoArchivoGit(
    String ruta,
    boolean existe,
    CommitGit ultimoCommit
) {}
