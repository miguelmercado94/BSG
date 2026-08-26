package com.bsg.soporterag.aplicacion.dto.request;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import lombok.Data;

@Data
@JsonIgnoreProperties(ignoreUnknown = true)
public class ChatRequestDto {
    private String mensaje;
}
