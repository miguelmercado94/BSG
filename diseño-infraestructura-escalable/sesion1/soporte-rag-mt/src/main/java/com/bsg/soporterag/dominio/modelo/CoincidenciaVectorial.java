package com.bsg.soporterag.dominio.modelo;

/**
 * Resultado de búsqueda por similitud coseno.
 */
public record CoincidenciaVectorial(
        String fuente,
        int indiceFragmento,
        double distancia
) {
}
