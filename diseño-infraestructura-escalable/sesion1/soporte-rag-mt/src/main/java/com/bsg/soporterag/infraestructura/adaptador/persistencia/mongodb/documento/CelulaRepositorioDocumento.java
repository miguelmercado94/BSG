package com.bsg.soporterag.infraestructura.adaptador.persistencia.mongodb.documento;

import lombok.Data;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.index.CompoundIndex;
import org.springframework.data.mongodb.core.mapping.Document;
import org.springframework.data.mongodb.core.mapping.Field;

/**
 * Colección de unión N:M entre {@link CelulaDocumento} y {@link RepositorioDocumento}.
 * Un mismo repo puede indexarse una sola vez y reutilizarse en varias células.
 */
@Data
@Document(collection = "celula_repositorio")
@CompoundIndex(name = "idx_celula_repo", def = "{'codigo_celula': 1, 'nombre_repo': 1}", unique = true)
public class CelulaRepositorioDocumento {

    @Id
    private String id;

    @Field("codigo_celula")
    private String codigoCelula;

    @Field("nombre_repo")
    private String nombreRepo;
}
