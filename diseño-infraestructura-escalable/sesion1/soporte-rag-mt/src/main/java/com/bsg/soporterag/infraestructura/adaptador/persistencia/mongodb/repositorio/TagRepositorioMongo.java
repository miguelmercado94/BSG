package com.bsg.soporterag.infraestructura.adaptador.persistencia.mongodb.repositorio;

import com.bsg.soporterag.infraestructura.adaptador.persistencia.mongodb.documento.TagDocumento;
import org.springframework.data.mongodb.repository.ReactiveMongoRepository;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.util.Collection;

public interface TagRepositorioMongo extends ReactiveMongoRepository<TagDocumento, String> {

    Mono<TagDocumento> findByTag(String tag);

    Flux<TagDocumento> findByTagIn(Collection<String> tags);

    Mono<Void> deleteByTag(String tag);
}
