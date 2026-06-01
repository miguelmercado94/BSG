package com.bsg.soporterag.dominio.excepcion;

public class CelulaNoEncontradaException extends RuntimeException {
    public CelulaNoEncontradaException(String codigoCelula) {
        super("No se encontró una célula con el código: " + codigoCelula);
    }
}
