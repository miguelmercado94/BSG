package com.bsg.soporterag.aplicacion.servicio;

import com.bsg.soporterag.dominio.modelo.CoincidenciaVectorial;
import reactor.core.publisher.Flux;

public interface ServicioBusquedaVectorial {

    Flux<CoincidenciaVectorial> buscarContexto(String urlRepo, String pregunta, int topK);
}
