package com.bsg.soporterag.infraestructura.adaptador.persistencia.mongodb.documento;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;

import lombok.Data;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.Document;
import org.springframework.data.mongodb.core.mapping.Field;

/**
 * Colección {@code repositorios}. Entidad global: un repo Git se indexa una vez (pgvector)
 * y puede asociarse a varias células sin re-embedding.
 * <p>
 * Los {@link com.bsg.soporterag.dominio.modelo.DocumentoSoporte} viven físicamente bajo
 * {@code urlFolderS3Workarea} (bucket workarea).
 */
@Data
@Document(collection = "repositorios")
public class RepositorioDocumento {

    @Id
    private String id;

    @Indexed(unique = true)
    @Field("nombre_repo")
    private String nombreRepo;

    @Field("descripcion_repo")
    private String descripcionRepo;

    @Indexed(unique = true)
    @Field("url_repo")
    private String urlRepo;

    @Field("files_path")
    private List<String> filesPath = new ArrayList<>();

    @Field("folder_path")
    private List<String> folderPath = new ArrayList<>();

    @Field("indexado")
    private boolean indexado;

    @Field("fecha_actualizacion")
    private Instant fechaActualizacion;

    @Field("rama_principal")
    private String ramaPrincipal;

    /** SHA del último commit en {@link #ramaPrincipal} (tip remoto). */
    @Field("ultimo_commit")
    private String ultimoCommit;

    /** Prefijo S3 (workarea) donde se almacenan los documentos de soporte del repo. */
    @Field("url_folder_s3_workarea")
    private String urlFolderS3Workarea;

    @Field("tags")
    private List<String> tags = new ArrayList<>(); // Lista de nombres de tags (referencia)
}
