package com.bsg.soporterag.dominio.modelo;

import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;

/**
 * Rutas relativas afectadas entre dos commits (para re-indexación selectiva).
 */
public record CambiosEntreCommitsGit(
        List<String> rutasAgregadas,
        List<String> rutasModificadas,
        List<String> rutasEliminadas
) {
    public List<String> todasLasRutasAfectadas() {
        Set<String> merged = new LinkedHashSet<>();
        if (rutasAgregadas != null) {
            merged.addAll(rutasAgregadas);
        }
        if (rutasModificadas != null) {
            merged.addAll(rutasModificadas);
        }
        if (rutasEliminadas != null) {
            merged.addAll(rutasEliminadas);
        }
        return new ArrayList<>(merged);
    }
}
