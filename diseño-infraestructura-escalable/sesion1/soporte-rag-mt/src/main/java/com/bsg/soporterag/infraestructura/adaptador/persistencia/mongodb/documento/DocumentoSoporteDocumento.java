package com.bsg.soporterag.infraestructura.adaptador.persistencia.mongodb.documento;

import java.time.Instant;

import com.bsg.soporterag.dominio.modelo.RolBucketS3;
import lombok.Data;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.index.CompoundIndex;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.Document;
import org.springframework.data.mongodb.core.mapping.Field;

/**
 * Persistencia Mongo de {@link com.bsg.soporterag.dominio.modelo.DocumentoSoporte}
 * (colección {@code soportes}).
 */
@Data
@Document(collection = "soportes")
@CompoundIndex(name = "idx_soporte_repo_codigo", def = "{'url_repo': 1, 'codigo_soporte': 1}", unique = true)
public class DocumentoSoporteDocumento {

    @Id
    private String id;

    @Field("url_repo")
    private String urlRepo;

    @Field("codigo_soporte")
    private String codigoSoporte;

    @Field("nombre")
    private String nombre;

    @Field("descripcion")
    private String descripcion;

    @Field("namespace_vectorial")
    private String namespaceVectorial;

    /** Clave o URI bajo el prefijo workarea del repo ({@code url_folder_s3_workarea}). */
    @Field("url_bucket_s3")
    private String urlBucketS3;

    @Field("bucket_rol")
    private RolBucketS3 bucketRol;

    @Field("indexado")
    private boolean indexado;

    @Field("actualizado_en")
    private Instant actualizadoEn;
}
