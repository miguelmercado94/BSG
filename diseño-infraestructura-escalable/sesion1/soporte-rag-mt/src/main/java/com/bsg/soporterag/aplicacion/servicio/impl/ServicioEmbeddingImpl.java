package com.bsg.soporterag.aplicacion.servicio.impl;

import com.bsg.soporterag.aplicacion.servicio.ServicioEmbedding;
import com.bsg.soporterag.dominio.modelo.FragmentoVectorial;
import com.bsg.soporterag.dominio.modelo.FuenteRag;
import com.bsg.soporterag.dominio.puerto.salida.AlmacenVectorialPort;
import com.bsg.soporterag.infraestructura.adaptador.ia.SpringAiEmbeddingAdaptador;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

@Service
public class ServicioEmbeddingImpl implements ServicioEmbedding {

    private static final int MAX_CONCURRENCY = 4;
    private static final int CHUNK_SIZE_FALLBACK = 800; // Tamaño de chunk aproximado en caracteres

    private final SpringAiEmbeddingAdaptador springAiEmbeddingAdaptador;
    private final AlmacenVectorialPort almacenVectorialPort;

    public ServicioEmbeddingImpl(
            SpringAiEmbeddingAdaptador springAiEmbeddingAdaptador,
            AlmacenVectorialPort almacenVectorialPort) {
        this.springAiEmbeddingAdaptador = springAiEmbeddingAdaptador;
        this.almacenVectorialPort = almacenVectorialPort;
    }

    @Override
    public Mono<Void> embedirArchivo(
            boolean esLocal,
            String namespace,
            String nombreArchivo,
            byte[] contenidoArchivo) {

        FuenteRag fuente = obtenerFuente(esLocal);
        String textoCompleto = new String(contenidoArchivo, StandardCharsets.UTF_8);
        List<String> chunks = dividirEnChunks(textoCompleto);

        if (chunks.isEmpty()) {
            return Mono.empty();
        }

        return springAiEmbeddingAdaptador
                .embedirLote(chunks)
                .flatMap(embeddings -> {
                    Flux<FragmentoVectorial> fragmentos =
                            Flux.range(0, embeddings.size())
                                    .map(indiceChunk -> {
                                        String idChunk = generarIdChunk(namespace, nombreArchivo, indiceChunk);
                                        return new FragmentoVectorial(
                                                idChunk,
                                                namespace,
                                                nombreArchivo,
                                                indiceChunk,
                                                chunks.get(indiceChunk),
                                                embeddings.get(indiceChunk)
                                        );
                                    });
                    return almacenVectorialPort.guardarLote(fuente, namespace, fragmentos);
                });
    }

    @Override
    public Mono<Void> embedirArchivos(
            boolean esLocal,
            String namespace,
            Map<String, byte[]> archivos) {
        return Flux.fromIterable(archivos.entrySet())
                .flatMap(entry -> embedirArchivo(esLocal, namespace, entry.getKey(), entry.getValue()), MAX_CONCURRENCY)
                .then();
    }

    @Override
    public Mono<Void> eliminarEmbedding(
            boolean esLocal,
            String namespace,
            String nombreArchivo) {
        FuenteRag fuente = obtenerFuente(esLocal);
        return almacenVectorialPort.eliminarDocumentos(fuente, namespace, List.of(nombreArchivo));
    }

    @Override
    public Mono<Void> actualizarEmbedding(
            boolean esLocal,
            String namespace,
            String nombreArchivo,
            byte[] contenidoArchivo) {
        return eliminarEmbedding(esLocal, namespace, nombreArchivo)
                .then(embedirArchivo(esLocal, namespace, nombreArchivo, contenidoArchivo));
    }

    @Override
    public Mono<Void> eliminarEmbeddings(
            boolean esLocal,
            String namespace,
            List<String> nombresArchivos) {
        FuenteRag fuente = obtenerFuente(esLocal);
        return almacenVectorialPort.eliminarDocumentos(fuente, namespace, nombresArchivos);
    }

    @Override
    public Mono<Void> eliminarTodosEmbeddingsPorRepo(String namespace) {
        Mono<Void> eliminarGit = almacenVectorialPort.eliminarNamespace(FuenteRag.GIT, namespace);
        Mono<Void> eliminarSoporte = almacenVectorialPort.eliminarNamespace(FuenteRag.SOPORTE, namespace);
        return Mono.when(eliminarGit, eliminarSoporte);
    }

    private FuenteRag obtenerFuente(boolean esLocal) {
        return esLocal ? FuenteRag.SOPORTE : FuenteRag.GIT;
    }

    /**
     * Implementación manual de chunking para evitar el conflicto con TokenTextSplitter.
     * Divide el texto en trozos de tamaño fijo.
     */
    private List<String> dividirEnChunks(String texto) {
        List<String> chunks = new ArrayList<>();
        if (texto == null || texto.isBlank()) {
            return chunks;
        }
        for (int i = 0; i < texto.length(); i += CHUNK_SIZE_FALLBACK) {
            chunks.add(texto.substring(i, Math.min(texto.length(), i + CHUNK_SIZE_FALLBACK)));
        }
        return chunks;
    }

    private String generarIdChunk(
            String namespace,
            String nombreArchivo,
            int indiceChunk) {
        return namespace + ":" + nombreArchivo + ":" + indiceChunk;
    }
}
