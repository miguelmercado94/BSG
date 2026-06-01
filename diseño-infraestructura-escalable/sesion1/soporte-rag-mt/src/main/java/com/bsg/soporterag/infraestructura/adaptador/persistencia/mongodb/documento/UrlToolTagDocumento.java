package com.bsg.soporterag.infraestructura.adaptador.persistencia.mongodb.documento;

import lombok.Data;
import org.springframework.data.mongodb.core.mapping.Field;

/**
 * Subdocumento embebido {@code url_tool_tag} dentro de {@link TagDocumento}.
 */
@Data
public class UrlToolTagDocumento {

    @Field("nombre_url")
    private String nombreUrl;

    @Field("url_tool")
    private String urlTool;

    @Field("contexto_url")
    private String contextoUrl;
}
