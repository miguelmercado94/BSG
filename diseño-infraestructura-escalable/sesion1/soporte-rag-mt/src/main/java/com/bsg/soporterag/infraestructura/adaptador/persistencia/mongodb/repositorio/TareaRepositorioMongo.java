package com.bsg.soporterag.infraestructura.adaptador.persistencia.mongodb.repositorio;

import com.bsg.soporterag.infraestructura.adaptador.persistencia.mongodb.documento.TareaDocumento;
import org.springframework.data.mongodb.repository.ReactiveMongoRepository;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

public interface TareaRepositorioMongo extends ReactiveMongoRepository<TareaDocumento, String> {

    Flux<TareaDocumento> findByUrlRepo(String urlRepo);

    Flux<TareaDocumento> findByCodigoUsuario(String codigoUsuario);

    Mono<TareaDocumento> findByCodigoTarea(String codigoTarea);

}
