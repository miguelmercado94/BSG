package com.bsg.soporterag.dominio.modelo;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.ArrayList;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class Tarea {
    private String id;
    private String codigoCelula;
    private String urlRepo;
    private String codigoUsuario;
    private String codigoTarea;
    private String titulo;
    private String enunciadoPrincipal;
    private EstadoTarea estadoTarea;
    private String urlFolderS3Borradores;
    private List<MensajeChat> msgChat = new ArrayList<>();
}
