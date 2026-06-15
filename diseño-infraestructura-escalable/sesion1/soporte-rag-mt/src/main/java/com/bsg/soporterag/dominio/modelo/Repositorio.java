package com.bsg.soporterag.dominio.modelo;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;

import lombok.Getter;
import lombok.Setter;

/**
 * Repositorio Git global (indexado una vez; asociación N:M con células aparte).
 */
@Getter
@Setter
public class Repositorio {

    private String id;
    private String nombre;
    /** Modo de conexión u otra descripción operativa (p. ej. HTTPS, SSH). */
    private String descripcion;
    private String url;
    private List<String> filesPath = new ArrayList<>();
    private List<String> folderPath = new ArrayList<>();
    private boolean indexado;
    private Instant fechaActualizacion;
    private String ramaPrincipal;
    private String ultimoCommit;
    private String urlFolderS3Workarea;
    private List<String> tags = new ArrayList<>(); // Lista de nombres de tags
}
