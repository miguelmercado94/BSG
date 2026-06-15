package com.bsg.soporterag.aplicacion.servicio.impl;

import com.bsg.soporterag.aplicacion.servicio.ServicioBusquedaVectorial;
import com.bsg.soporterag.dominio.modelo.CoincidenciaVectorial;
import com.bsg.soporterag.dominio.modelo.FuenteRag;
import com.bsg.soporterag.dominio.puerto.salida.AlmacenVectorialPort;
import com.bsg.soporterag.dominio.puerto.salida.ProveedorEmbeddingPort;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Flux;

@Service
public class ServicioBusquedaVectorialImpl implements ServicioBusquedaVectorial {

    private final ProveedorEmbeddingPort proveedorEmbeddingPort;
    private final AlmacenVectorialPort almacenVectorialPort;

    public ServicioBusquedaVectorialImpl(
            ProveedorEmbeddingPort proveedorEmbeddingPort, 
            AlmacenVectorialPort almacenVectorialPort) {
        this.proveedorEmbeddingPort = proveedorEmbeddingPort;
        this.almacenVectorialPort = almacenVectorialPort;
    }

    @Override
    public Flux<CoincidenciaVectorial> buscarContexto(String urlRepo, String pregunta, int topK) {
        return proveedorEmbeddingPort.embedir(pregunta)
                .flatMapMany(embedding -> {
                    Flux<CoincidenciaVectorial> resultadosGit = almacenVectorialPort.buscarSimilares(
                            FuenteRag.GIT, urlRepo, embedding, topK);
                    
                    Flux<CoincidenciaVectorial> resultadosSoporte = almacenVectorialPort.buscarSimilares(
                            FuenteRag.SOPORTE, urlRepo, embedding, topK);
                    
                    return Flux.merge(resultadosGit, resultadosSoporte);
                });
    }
}
