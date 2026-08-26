package com.bsg.soporterag.aplicacion.servicio.impl;

import com.bsg.soporterag.configuracion.VectorPropiedades;
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

    private final SpringAiEmbeddingAdaptador springAiEmbeddingAdaptador;
    private final AlmacenVectorialPort almacenVectorialPort;
    private final VectorPropiedades propiedades;

    public ServicioEmbeddingImpl(
            SpringAiEmbeddingAdaptador springAiEmbeddingAdaptador,
            AlmacenVectorialPort almacenVectorialPort,
            VectorPropiedades propiedades) {
        this.springAiEmbeddingAdaptador = springAiEmbeddingAdaptador;
        this.almacenVectorialPort = almacenVectorialPort;
        this.propiedades = propiedades;
    }

    @Override
    public Mono<Void> embedirArchivo(
            boolean esLocal,
            String namespace,
            String nombreArchivo,
            byte[] contenidoArchivo) {

        long limiteBytes = (long) propiedades.maxFileSizeMb() * 1024 * 1024;
        if (contenidoArchivo != null && contenidoArchivo.length > limiteBytes) {
            return Mono.error(new IllegalArgumentException("El archivo supera el tamaño máximo permitido de " + propiedades.maxFileSizeMb() + " MB."));
        }

        if (esArchivoBinario(contenidoArchivo)) {
            return Mono.error(new IllegalArgumentException("El archivo es de tipo binario y no es indexable."));
        }

        FuenteRag fuente = obtenerFuente(esLocal);
        String textoCompleto = new String(contenidoArchivo, StandardCharsets.UTF_8);
        List<String> chunks = dividirEnChunks(textoCompleto, propiedades.chunkSize(), propiedades.chunkOverlap());

        if (chunks.isEmpty()) {
            return Mono.empty();
        }

        int batchSize = propiedades.embeddingBatchSize() > 0 ? propiedades.embeddingBatchSize() : 32;
        List<List<String>> batches = partition(chunks, batchSize);

        return Flux.fromIterable(batches)
                .flatMap(batch -> springAiEmbeddingAdaptador.embedirLote(batch), 1)
                .collectList()
                .flatMap(listOfLists -> {
                    List<float[]> allEmbeddings = new ArrayList<>();
                    for (List<float[]> list : listOfLists) {
                        allEmbeddings.addAll(list);
                    }
                    
                    Flux<FragmentoVectorial> fragmentos =
                            Flux.range(0, allEmbeddings.size())
                                    .map(indiceChunk -> {
                                        String idChunk = generarIdChunk(namespace, nombreArchivo, indiceChunk);
                                        return new FragmentoVectorial(
                                                idChunk,
                                                namespace,
                                                nombreArchivo,
                                                indiceChunk,
                                                chunks.get(indiceChunk),
                                                allEmbeddings.get(indiceChunk)
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
     * Implementación manual de chunking con tamaño de fragmento y solapamiento variables.
     */
    private List<String> dividirEnChunks(String texto, int chunkSize, int chunkOverlap) {
        List<String> chunks = new ArrayList<>();
        if (texto == null || texto.isBlank()) {
            return chunks;
        }
        if (chunkSize <= 0) {
            chunkSize = 800;
        }
        if (chunkOverlap < 0 || chunkOverlap >= chunkSize) {
            chunkOverlap = 0;
        }
        
        int start = 0;
        int limit = texto.length();
        while (start < limit) {
            int end = Math.min(start + chunkSize, limit);
            chunks.add(texto.substring(start, end));
            if (end == limit) {
                break;
            }
            start = end - chunkOverlap;
            if (start >= end) {
                start = end;
            }
        }
        return chunks;
    }

    private boolean esArchivoBinario(byte[] contenido) {
        if (contenido == null) return false;
        int limite = Math.min(contenido.length, 1024);
        for (int i = 0; i < limite; i++) {
            if (contenido[i] == 0) {
                return true;
            }
        }
        return false;
    }

    private <T> List<List<T>> partition(List<T> list, int size) {
        List<List<T>> partitions = new ArrayList<>();
        for (int i = 0; i < list.size(); i += size) {
            partitions.add(new ArrayList<>(list.subList(i, Math.min(i + size, list.size()))));
        }
        return partitions;
    }

    private String generarIdChunk(
            String namespace,
            String nombreArchivo,
            int indiceChunk) {
        String rawId = namespace + ":" + nombreArchivo + ":" + indiceChunk;
        try {
            java.security.MessageDigest digest = java.security.MessageDigest.getInstance("MD5");
            byte[] hash = digest.digest(rawId.getBytes(java.nio.charset.StandardCharsets.UTF_8));
            StringBuilder hexString = new StringBuilder();
            for (byte b : hash) {
                String hex = Integer.toHexString(0xff & b);
                if (hex.length() == 1) hexString.append('0');
                hexString.append(hex);
            }
            return hexString.toString();
        } catch (java.security.NoSuchAlgorithmException e) {
            return String.valueOf(rawId.hashCode());
        }
    }
}
