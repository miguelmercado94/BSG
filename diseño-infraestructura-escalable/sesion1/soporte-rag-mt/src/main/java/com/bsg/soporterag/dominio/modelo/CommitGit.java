package com.bsg.soporterag.dominio.modelo;

public record CommitGit(
    String hash,
    String mensaje,
    String autor
) {}
