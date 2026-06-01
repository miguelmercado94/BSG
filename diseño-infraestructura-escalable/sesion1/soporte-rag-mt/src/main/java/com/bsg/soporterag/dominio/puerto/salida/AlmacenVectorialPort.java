package com.bsg.soporterag.dominio.puerto.salida;

import com.bsg.soporterag.dominio.modelo.CoincidenciaVectorial;
import com.bsg.soporterag.dominio.modelo.FragmentoVectorial;
import com.bsg.soporterag.dominio.modelo.FuenteRag;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.util.List;

/**
 * Almacén vectorial pgvector. Cada {@link FuenteRag} usa una tabla PostgreSQL distinta.
 */
public interface AlmacenVectorialPort {

    Mono<Void> guardarLote(FuenteRag fuente, String namespace, Flux<FragmentoVectorial> fragmentos);

    Flux<CoincidenciaVectorial> buscarSimilares(FuenteRag fuente, String namespace, float[] embedding, int topK);

    Mono<Void> eliminarNamespace(FuenteRag fuente, String namespace);

    Mono<Void> eliminarDocumentos(FuenteRag fuente, String namespace, List<String> documentos);
}