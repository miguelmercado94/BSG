package com.bsg.soporterag.aplicacion.mapperdto;

import com.bsg.soporterag.aplicacion.dto.UrlToolTagDto;
import com.bsg.soporterag.aplicacion.dto.request.CrearTagRequestDto;
import com.bsg.soporterag.aplicacion.dto.response.TagResponseDto;
import com.bsg.soporterag.dominio.modelo.Tag;
import com.bsg.soporterag.dominio.modelo.UrlToolTag;
import org.springframework.stereotype.Component;

import java.util.Collections;
import java.util.stream.Collectors;

@Component
public class TagDtoMapper {

    public Tag aDominio(CrearTagRequestDto dto) {
        Tag tag = new Tag();
        tag.setTag(dto.getTag());
        tag.setDescripcionTag(dto.getDescripcionTag());
        tag.setHabilitado(true); // Siempre se crea habilitado
        if (dto.getHerramientasUrls() != null) {
            tag.setUrlToolTag(dto.getHerramientasUrls().stream()
                    .map(this::aDominio)
                    .collect(Collectors.toList()));
        } else {
            tag.setUrlToolTag(Collections.emptyList());
        }
        return tag;
    }

    public TagResponseDto aResponse(Tag tag) {
        TagResponseDto dto = new TagResponseDto();
        dto.setTag(tag.getTag());
        dto.setDescripcionTag(tag.getDescripcionTag());
        dto.setHabilitado(tag.isHabilitado());
        if (tag.getUrlToolTag() != null) {
            dto.setHerramientasUrls(tag.getUrlToolTag().stream()
                    .map(this::aDto)
                    .collect(Collectors.toList()));
        } else {
            dto.setHerramientasUrls(Collections.emptyList());
        }
        return dto;
    }

    private UrlToolTag aDominio(UrlToolTagDto dto) {
        return new UrlToolTag(dto.getUrlTool(), dto.getContextoUrl());
    }

    private UrlToolTagDto aDto(UrlToolTag dominio) {
        UrlToolTagDto dto = new UrlToolTagDto();
        dto.setUrlTool(dominio.getUrlTool());
        dto.setContextoUrl(dominio.getContextoUrl());
        return dto;
    }
}
