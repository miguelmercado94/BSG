package com.bsg.soporterag.aplicacion.puerto.entrada;

import com.bsg.soporterag.aplicacion.dto.response.SaludInfraestructuraDto;
import reactor.core.publisher.Mono;

public interface ConsultarSaludInfraestructuraCasoDeUso {

    Mono<SaludInfraestructuraDto> ejecutar();
}
