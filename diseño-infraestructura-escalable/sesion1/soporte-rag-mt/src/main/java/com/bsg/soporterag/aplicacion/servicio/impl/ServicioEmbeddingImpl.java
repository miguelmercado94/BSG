package com.bsg.soporterag.aplicacion.servicio.impl;

import com.bsg.soporterag.aplicacion.servicio.ServicioEmbedding;
import com.bsg.soporterag.dominio.modelo.FragmentoVectorial;
import com.bsg.soporterag.dominio.modelo.FuenteRag;
import com.bsg.soporterag.dominio.puerto.salida.AlmacenVectorialPort;
import com.bsg.soporterag.infraestructura.adaptador.ia.SpringAiEmbeddingAdaptador;
import org.springframework.ai.document.Document;
import org.springframework.ai.transformer.splitter.TokenTextSplitter;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.Map;

@Service
public class ServicioEmbeddingImpl implements ServicioEmbedding {

    private static final int MAX_CONCURRENCY = 4;

    private final SpringAiEmbeddingAdaptador springAiEmbeddingAdaptador;
    private final AlmacenVectorialPort almacenVectorialPort;
    private final TokenTextSplitter tokenTextSplitter;

    public ServicioEmbeddingImpl(
            SpringAiEmbeddingAdaptador springAiEmbeddingAdaptador,
            AlmacenVectorialPort almacenVectorialPort,
            TokenTextSplitter tokenTextSplitter) {

        this.springAiEmbeddingAdaptador = springAiEmbeddingAdaptador;
        this.almacenVectorialPort = almacenVectorialPort;
        this.tokenTextSplitter = tokenTextSplitter;
    }

    @Override
    public Mono<Void> embedirArchivo(
            boolean esLocal,
            String nombreRepo,
            String nombreArchivo,
            byte[] contenidoArchivo) {

        FuenteRag fuente = obtenerFuente(esLocal);

        String textoCompleto =
                new String(contenidoArchivo, StandardCharsets.UTF_8);

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

                                        String idChunk =
                                                generarIdChunk(
                                                        nombreRepo,
                                                        nombreArchivo,
                                                        indiceChunk);

                                        return new FragmentoVectorial(
                                                idChunk,
                                                nombreRepo,
                                                nombreArchivo,
                                                indiceChunk,
                                                embeddings.get(indiceChunk)
                                        );
                                    });

                    return almacenVectorialPort.guardarLote(
                            fuente,
                            nombreRepo,
                            fragmentos
                    );
                });
    }

    @Override
    public Mono<Void> embedirArchivos(
            boolean esLocal,
            String nombreRepo,
            Map<String, byte[]> archivos) {

        return Flux.fromIterable(archivos.entrySet())
                .flatMap(
                        entry -> embedirArchivo(
                                esLocal,
                                nombreRepo,
                                entry.getKey(),
                                entry.getValue()
                        ),
                        MAX_CONCURRENCY
                )
                .then();
    }

    @Override
    public Mono<Void> eliminarEmbedding(
            boolean esLocal,
            String nombreRepo,
            String nombreArchivo) {

        FuenteRag fuente = obtenerFuente(esLocal);

        return almacenVectorialPort.eliminarDocumentos(
                fuente,
                nombreRepo,
                List.of(nombreArchivo)
        );
    }

    @Override
    public Mono<Void> actualizarEmbedding(
            boolean esLocal,
            String nombreRepo,
            String nombreArchivo,
            byte[] contenidoArchivo) {

        return eliminarEmbedding(
                esLocal,
                nombreRepo,
                nombreArchivo
        ).then(
                embedirArchivo(
                        esLocal,
                        nombreRepo,
                        nombreArchivo,
                        contenidoArchivo
                )
        );
    }

    @Override
    public Mono<Void> eliminarEmbeddings(
            boolean esLocal,
            String nombreRepo,
            List<String> nombresArchivos) {

        FuenteRag fuente = obtenerFuente(esLocal);

        return almacenVectorialPort.eliminarDocumentos(
                fuente,
                nombreRepo,
                nombresArchivos
        );
    }

    @Override
    public Mono<Void> eliminarTodosEmbeddingsPorRepo(
            String nombreRepo) {

        Mono<Void> eliminarGit =
                almacenVectorialPort.eliminarNamespace(
                        FuenteRag.GIT,
                        nombreRepo
                );

        Mono<Void> eliminarSoporte =
                almacenVectorialPort.eliminarNamespace(
                        FuenteRag.SOPORTE,
                        nombreRepo
                );

        return Mono.when(
                eliminarGit,
                eliminarSoporte
        );
    }

    private FuenteRag obtenerFuente(boolean esLocal) {
        return esLocal
                ? FuenteRag.SOPORTE
                : FuenteRag.GIT;
    }

    private List<String> dividirEnChunks(String texto) {

        Document documento = new Document(texto);

        return tokenTextSplitter
                .apply(List.of(documento))
                .stream()
                .map(Document::getText)
                .toList();
    }

    private String generarIdChunk(
            String nombreRepo,
            String nombreArchivo,
            int indiceChunk) {

        return nombreRepo
                + ":"
                + nombreArchivo
                + ":"
                + indiceChunk;
    }
}