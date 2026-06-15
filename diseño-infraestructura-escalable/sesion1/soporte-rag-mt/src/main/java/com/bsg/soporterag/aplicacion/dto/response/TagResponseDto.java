package com.bsg.soporterag.aplicacion.dto.response;

import com.bsg.soporterag.aplicacion.dto.UrlToolTagDto;
import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.Data;

import java.util.List;

@Data
@JsonInclude(JsonInclude.Include.NON_NULL)
public class TagResponseDto {
    private String tag;
    private String descripcionTag;
    private boolean habilitado;
    private List<UrlToolTagDto> herramientasUrls;
}
