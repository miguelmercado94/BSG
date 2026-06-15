package com.bsg.soporterag.aplicacion.mapperdto;

import com.bsg.soporterag.aplicacion.dto.request.CrearTareaRequestDto;
import com.bsg.soporterag.aplicacion.dto.response.MensajeChatDto;
import com.bsg.soporterag.aplicacion.dto.response.TareaResponseDto;
import com.bsg.soporterag.dominio.modelo.EstadoTarea;
import com.bsg.soporterag.dominio.modelo.MensajeChat;
import com.bsg.soporterag.dominio.modelo.Tarea;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.Collections;
import java.util.stream.Collectors;

@Component
public class TareaDtoMapper {

    public Tarea aDominio(CrearTareaRequestDto dto) {
        Tarea tarea = new Tarea();
        tarea.setCodigoCelula(dto.getCodigoCelula());
        tarea.setUrlRepo(dto.getUrlRepo());
        tarea.setCodigoUsuario(dto.getCodigoUsuario());
        tarea.setCodigoTarea(dto.getCodigoTarea());
        tarea.setTitulo(dto.getTitulo());
        tarea.setEnunciadoPrincipal(dto.getEnunciadoPrincipal());
        tarea.setEstadoTarea(EstadoTarea.BORRADOR); // Estado inicial
        tarea.setMsgChat(new ArrayList<>());
        return tarea;
    }

    public TareaResponseDto aResponse(Tarea dominio) {
        TareaResponseDto dto = new TareaResponseDto();
        dto.setCodigoCelula(dominio.getCodigoCelula());
        dto.setUrlRepo(dominio.getUrlRepo());
        dto.setCodigoUsuario(dominio.getCodigoUsuario());
        dto.setCodigoTarea(dominio.getCodigoTarea());
        dto.setTitulo(dominio.getTitulo());
        dto.setEnunciadoPrincipal(dominio.getEnunciadoPrincipal());
        dto.setEstadoTarea(dominio.getEstadoTarea());

        if (dominio.getMsgChat() != null) {
            dto.setMsgChat(dominio.getMsgChat().stream()
                    .map(this::aDto)
                    .collect(Collectors.toList()));
        } else {
            dto.setMsgChat(Collections.emptyList());
        }

        return dto;
    }

    public MensajeChatDto aDto(MensajeChat dominio) {
        if (dominio == null) {
            return null;
        }
        MensajeChatDto dto = new MensajeChatDto();
        dto.setTextoEntrada(dominio.getTextoEntrada());
        dto.setTextoFormateado(dominio.getTextoFormateado());
        dto.setTextoRespuesta(dominio.getTextoRespuesta());
        dto.setFechaRespuesta(dominio.getFechaRespuesta());
        dto.setHoraRespuesta(dominio.getHoraRespuesta());
        return dto;
    }
}
