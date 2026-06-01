package com.bsg.soporterag.infraestructura.adaptador.ia;

import com.bsg.soporterag.dominio.puerto.salida.ProveedorEmbeddingPort;
import org.springframework.ai.embedding.EmbeddingModel;
import org.springframework.ai.embedding.EmbeddingRequest;
import org.springframework.ai.embedding.EmbeddingResponse;
import org.springframework.stereotype.Component;
import reactor.core.publisher.Mono;
import reactor.core.scheduler.Schedulers;

import java.util.List;

@Component
public class SpringAiEmbeddingAdaptador implements ProveedorEmbeddingPort {

    private final EmbeddingModel embeddingModel;

    public SpringAiEmbeddingAdaptador(EmbeddingModel embeddingModel) {
        this.embeddingModel = embeddingModel;
    }

    @Override
    public Mono<float[]> embedir(String texto) {
        return Mono.fromCallable(() -> embeddingModel.embed(texto))
                .subscribeOn(Schedulers.boundedElastic());
    }

    @Override
    public Mono<List<float[]>> embedirLote(List<String> textos) {
        return Mono.fromCallable(() -> {
                    EmbeddingResponse response = embeddingModel.call(new EmbeddingRequest(textos, null));
                    return response.getResults().stream()
                            .map(r -> r.getOutput())
                            .toList();
                })
                .subscribeOn(Schedulers.boundedElastic());
    }
}