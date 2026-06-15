package com.bsg.soporterag.infraestructura.adaptador.persistencia.mongodb.mapper;

import com.bsg.soporterag.dominio.modelo.MensajeChat;
import com.bsg.soporterag.dominio.modelo.Tarea;
import com.bsg.soporterag.infraestructura.adaptador.persistencia.mongodb.documento.MensajeChatDocumento;
import com.bsg.soporterag.infraestructura.adaptador.persistencia.mongodb.documento.TareaDocumento;
import org.springframework.stereotype.Component;

import java.util.Collections;
import java.util.stream.Collectors;

@Component
public class TareaDocumentoMapper {

    public Tarea aDominio(TareaDocumento documento) {
        if (documento == null) {
            return null;
        }
        Tarea dominio = new Tarea();
        dominio.setId(documento.getId());
        dominio.setCodigoCelula(documento.getCodigoCelula());
        dominio.setUrlRepo(documento.getUrlRepo());
        dominio.setCodigoUsuario(documento.getCodigoUsuario());
        dominio.setCodigoTarea(documento.getCodigoTarea());
        dominio.setTitulo(documento.getTitulo());
        dominio.setEnunciadoPrincipal(documento.getEnunciadoPrincipal());
        dominio.setResumen(documento.getResumen());
        dominio.setEstadoTarea(documento.getEstadoTarea());
        dominio.setUrlFolderS3Borradores(documento.getUrlFolderS3Borradores());

        if (documento.getMsgChat() != null) {
            dominio.setMsgChat(documento.getMsgChat().stream()
                    .map(this::mensajeChatADominio)
                    .collect(Collectors.toList()));
        } else {
            dominio.setMsgChat(Collections.emptyList());
        }
        return dominio;
    }

    public TareaDocumento aDocumento(Tarea dominio) {
        if (dominio == null) {
            return null;
        }
        TareaDocumento documento = new TareaDocumento();
        documento.setId(dominio.getId());
        documento.setCodigoCelula(dominio.getCodigoCelula());
        documento.setUrlRepo(dominio.getUrlRepo());
        documento.setCodigoUsuario(dominio.getCodigoUsuario());
        documento.setCodigoTarea(dominio.getCodigoTarea());
        documento.setTitulo(dominio.getTitulo());
        documento.setEnunciadoPrincipal(dominio.getEnunciadoPrincipal());
        documento.setResumen(dominio.getResumen());
        documento.setEstadoTarea(dominio.getEstadoTarea());
        documento.setUrlFolderS3Borradores(dominio.getUrlFolderS3Borradores());

        if (dominio.getMsgChat() != null) {
            documento.setMsgChat(dominio.getMsgChat().stream()
                    .map(this::mensajeChatADocumento)
                    .collect(Collectors.toList()));
        } else {
            documento.setMsgChat(Collections.emptyList());
        }
        return documento;
    }

    public MensajeChat mensajeChatADominio(MensajeChatDocumento documento) {
        if (documento == null) {
            return null;
        }
        return new MensajeChat(
                documento.getTextoEntrada(),
                documento.getTextoFormateado(),
                documento.getTextoRespuesta(),
                documento.getFechaRespuesta(),
                documento.getHoraRespuesta()
        );
    }

    public MensajeChatDocumento mensajeChatADocumento(MensajeChat dominio) {
        if (dominio == null) {
            return null;
        }
        MensajeChatDocumento documento = new MensajeChatDocumento();
        documento.setTextoEntrada(dominio.getTextoEntrada());
        documento.setTextoFormateado(dominio.getTextoFormateado());
        documento.setTextoRespuesta(dominio.getTextoRespuesta());
        documento.setFechaRespuesta(dominio.getFechaRespuesta());
        documento.setHoraRespuesta(dominio.getHoraRespuesta());
        return documento;
    }
}
