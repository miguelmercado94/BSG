package com.bsg.soporterag.aplicacion.dto.response;

import com.bsg.soporterag.dominio.modelo.EstadoTarea;
import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.Data;

import java.util.List;

@Data
@JsonInclude(JsonInclude.Include.NON_NULL)
public class TareaResponseDto {
    private String codigoCelula;
    private String urlRepo;
    private String codigoUsuario;
    private String codigoTarea;
    private String titulo;
    private String enunciadoPrincipal;
    private EstadoTarea estadoTarea;
    private List<MensajeChatDto> msgChat;
}
