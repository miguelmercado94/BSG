package com.bsg.soporterag.aplicacion.servicio;

import com.bsg.soporterag.infraestructura.adaptador.ia.model.PropuestaModificacionArchivoDtoIa;
import reactor.core.publisher.Mono;

public interface ServicioDeParches {

    /**
     * Aplica una propuesta de modificación a un archivo y genera un parche en formato diff.
     * @param propuesta La propuesta de modificación que contiene los cambios.
     * @param contenidoOriginal El contenido original del archivo como un string.
     * @return Un string con el parche en formato diff.
     */
    Mono<String> generarDiff(PropuestaModificacionArchivoDtoIa propuesta, String contenidoOriginal);

}
