package com.bsg.soporterag.infraestructura.adaptador.persistencia.mongodb.mapper;

import com.bsg.soporterag.dominio.modelo.Tag;
import com.bsg.soporterag.dominio.modelo.UrlToolTag;
import com.bsg.soporterag.infraestructura.adaptador.persistencia.mongodb.documento.TagDocumento;
import com.bsg.soporterag.infraestructura.adaptador.persistencia.mongodb.documento.UrlToolTagDocumento;
import org.springframework.stereotype.Component;

import java.util.stream.Collectors;
import java.util.Collections;

@Component
public class TagDocumentoMapper {

    public Tag aDominio(TagDocumento documento) {
        if (documento == null) {
            return null;
        }
        Tag dominio = new Tag();
        dominio.setTag(documento.getTag());
        dominio.setDescripcionTag(documento.getDescripcionTag());
        dominio.setHabilitado(documento.isHabilitado());

        if (documento.getUrlToolTag() != null) {
            dominio.setUrlToolTag(documento.getUrlToolTag().stream()
                    .map(this::urlToolTagADominio)
                    .collect(Collectors.toList()));
        } else {
            dominio.setUrlToolTag(Collections.emptyList());
        }

        return dominio;
    }

    public TagDocumento aDocumento(Tag dominio) {
        if (dominio == null) {
            return null;
        }
        TagDocumento documento = new TagDocumento();
        documento.setTag(dominio.getTag());
        documento.setDescripcionTag(dominio.getDescripcionTag());
        documento.setHabilitado(dominio.isHabilitado());

        if (dominio.getUrlToolTag() != null) {
            documento.setUrlToolTag(dominio.getUrlToolTag().stream()
                    .map(this::urlToolTagADocumento)
                    .collect(Collectors.toList()));
        } else {
            documento.setUrlToolTag(Collections.emptyList());
        }

        return documento;
    }

    public UrlToolTag urlToolTagADominio(UrlToolTagDocumento documento) {
        if (documento == null) {
            return null;
        }
        return new UrlToolTag(
                documento.getUrlTool(),
                documento.getContextoUrl()
        );
    }

    public UrlToolTagDocumento urlToolTagADocumento(UrlToolTag dominio) {
        if (dominio == null) {
            return null;
        }
        UrlToolTagDocumento documento = new UrlToolTagDocumento();
        documento.setUrlTool(dominio.getUrlTool());
        documento.setContextoUrl(dominio.getContextoUrl());
        return documento;
    }
}
