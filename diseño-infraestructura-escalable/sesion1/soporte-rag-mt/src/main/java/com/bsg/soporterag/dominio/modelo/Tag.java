package com.bsg.soporterag.dominio.modelo;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.ArrayList;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class Tag {
    private String id;
    private String tag;
    private String descripcionTag;
    private boolean habilitado;
    private List<UrlToolTag> urlToolTag = new ArrayList<>();
}
