package com.bsg.soporterag.infraestructura.adaptador.persistencia.mongodb.repositorio;

import com.bsg.soporterag.infraestructura.adaptador.persistencia.mongodb.documento.RepositorioDocumento;
import org.springframework.data.mongodb.repository.ReactiveMongoRepository;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

public interface RepositorioRepositorioMongo extends ReactiveMongoRepository<RepositorioDocumento, String> {

    Mono<RepositorioDocumento> findByUrlRepo(String urlRepo);

    Mono<RepositorioDocumento> findByNombreRepo(String nombreRepo);

    Flux<RepositorioDocumento> findByTagsContains(String nombreTag);
}
