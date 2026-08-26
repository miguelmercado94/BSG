package com.bsg.soporterag.aplicacion.dto.response;

import lombok.Data;
import java.util.List;

@Data
public class RepositorioResponseDto {
    private String nombre;
    private String url;
    private String ramaPrincipal;
    private String ultimoCommit;
    private String descripcion;
    private boolean indexado;
    private String urlFolderS3Workarea;
    private List<CelulaResumenDto> celulasAsociadas;
    private List<String> archivosS3Workarea;
    private List<String> filesPath;
    private List<String> folderPath;
    private String vectorNamespace;
    private List<String> tags;
}