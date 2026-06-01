package com.bsg.soporterag.infraestructura.adaptador.persistencia.mongodb.documento;

import lombok.Data;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.Document;
import org.springframework.data.mongodb.core.mapping.Field;

/**
 * Colección {@code celulas}. La asociación con repos es N:M vía {@link CelulaRepositorioDocumento}.
 */
@Data
@Document(collection = "celulas")
public class CelulaDocumento {

    @Id
    private String id;

    @Indexed(unique = true)
    @Field("codigo_celula")
    private String codigoCelula;

    @Field("nombre_celula")
    private String nombreCelula;

    @Field("descripcion_celula")
    private String descripcionCelula;
}
