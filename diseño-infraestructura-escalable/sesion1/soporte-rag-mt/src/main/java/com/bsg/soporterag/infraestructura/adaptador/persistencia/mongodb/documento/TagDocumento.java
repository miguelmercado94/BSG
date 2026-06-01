package com.bsg.soporterag.infraestructura.adaptador.persistencia.mongodb.documento;

import java.util.ArrayList;
import java.util.List;

import lombok.Data;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.index.CompoundIndex;
import org.springframework.data.mongodb.core.mapping.Document;
import org.springframework.data.mongodb.core.mapping.Field;

/**
 * Colección {@code tags}. Herramientas RAG embebidas en {@code url_tool_tag}.
 */
@Data
@Document(collection = "tags")
@CompoundIndex(name = "idx_tag_repo", def = "{'codigo_celula': 1, 'nombre_repo': 1, 'tag': 1}", unique = true)
public class TagDocumento {

    @Id
    private String id;

    @Field("codigo_celula")
    private String codigoCelula;

    @Field("nombre_repo")
    private String nombreRepo;

    @Field("tag")
    private String tag;

    @Field("descripcion_tag")
    private String descripcionTag;

    @Field("url_tool_tag")
    private List<UrlToolTagDocumento> urlToolTag = new ArrayList<>();
}
