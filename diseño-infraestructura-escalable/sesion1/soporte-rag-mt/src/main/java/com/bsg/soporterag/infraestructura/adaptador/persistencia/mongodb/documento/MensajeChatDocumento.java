package com.bsg.soporterag.infraestructura.adaptador.persistencia.mongodb.documento;

import java.time.Instant;
import java.time.LocalDate;

import lombok.Data;
import org.springframework.data.mongodb.core.mapping.Field;

/**
 * Subdocumento embebido {@code msg_chat} dentro de {@link TareaDocumento}.
 */
@Data
public class MensajeChatDocumento {

    @Field("texto_entrada")
    private String textoEntrada;

    @Field("texto_formateado")
    private String textoFormateado;

    @Field("texto_respuesta")
    private String textoRespuesta;

    @Field("fecha_respuesta")
    private LocalDate fechaRespuesta;

    @Field("hora_respuesta")
    private Instant horaRespuesta;
}
