package com.bsg.soporterag.infraestructura.adaptador.ia.model;

import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

@Data
@NoArgsConstructor
public class PropuestaModificacionArchivoDtoIa {
    private String urlRepo;
    private String rama;
    private String commit;
    private String filePath;
    private List<CambioPropuestoDtoIa> cambios = new ArrayList<>();

    public PropuestaModificacionArchivoDtoIa(String urlRepo, String rama, String commit, String filePath, List<CambioPropuestoDtoIa> cambios) {
        this.urlRepo = urlRepo;
        this.rama = rama;
        this.commit = commit;
        this.filePath = filePath;
        
        // Aseguramos que al crear el objeto, la lista se guarde ordenada de forma descendente
        if (cambios != null) {
            this.cambios = new ArrayList<>(cambios);
            Collections.sort(this.cambios);
        }
    }

    public void setCambios(List<CambioPropuestoDtoIa> cambios) {
        if (cambios != null) {
            this.cambios = new ArrayList<>(cambios);
            // Cada vez que se asigne una nueva lista, nos aseguramos de que esté ordenada
            Collections.sort(this.cambios);
        } else {
            this.cambios = new ArrayList<>();
        }
    }
    
    public void agregarCambio(CambioPropuestoDtoIa cambio) {
        if (cambio != null) {
            this.cambios.add(cambio);
            Collections.sort(this.cambios);
        }
    }
}
