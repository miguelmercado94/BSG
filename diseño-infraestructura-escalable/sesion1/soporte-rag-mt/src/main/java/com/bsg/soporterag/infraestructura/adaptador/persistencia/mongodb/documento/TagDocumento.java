package com.bsg.soporterag.infraestructura.adaptador.persistencia.mongodb.documento;

import java.util.ArrayList;
import java.util.List;

import lombok.Data;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.Document;
import org.springframework.data.mongodb.core.mapping.Field;

/**
 * Colección global de Tags. Cada tag es único y puede ser asociado a múltiples repositorios.
 */
@Data
@Document(collection = "tags")
public class TagDocumento {

    @Id
    private String id;

    @Indexed(unique = true)
    @Field("tag")
    private String tag;

    @Field("descripcion_tag")
    private String descripcionTag;

    @Field("habilitado")
    private boolean habilitado = true;

    @Field("url_tool_tag")
    private List<UrlToolTagDocumento> urlToolTag = new ArrayList<>();
}
