package com.bsg.soporterag.aplicacion.dto.request;

import com.bsg.soporterag.aplicacion.dto.UrlToolTagDto;
import lombok.Data;

import java.util.List;

@Data
public class CrearTagRequestDto {
    private String tag;
    private String descripcionTag;
    private List<UrlToolTagDto> herramientasUrls;
}
