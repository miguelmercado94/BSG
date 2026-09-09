package com.bsg.soporterag.infraestructura.adaptador.persistencia.mongodb.documento;

import com.bsg.soporterag.dominio.modelo.EstadoTarea;
import java.util.ArrayList;
import java.util.List;

import lombok.Data;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.index.CompoundIndex;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.Document;
import org.springframework.data.mongodb.core.mapping.Field;

/**
 * Colección {@code tareas}. Incluye historial RAG embebido {@code msg_chat}.
 */
@Data
@Document(collection = "tareas")
@CompoundIndex(name = "idx_tarea_celula_codigo", def = "{'codigo_celula': 1, 'codigo_tarea': 1}", unique = true)
public class TareaDocumento {

    @Id
    private String id;

    @Field("codigo_celula")
    private String codigoCelula;

    @Indexed
    @Field("url_repo")
    private String urlRepo;

    @Indexed
    @Field("codigo_usuario")
    private String codigoUsuario;

    @Field("codigo_tarea")
    private String codigoTarea;

    @Field("titulo")
    private String titulo;

    @Field("enunciado_principal")
    private String enunciadoPrincipal;

    @Field("estado_tarea")
    private EstadoTarea estadoTarea;

    @Field("url_folder_s3_borradores")
    private String urlFolderS3Borradores;

    @Field("msg_chat")
    private List<MensajeChatDocumento> msgChat = new ArrayList<>();
}
