package com.bsg.soporterag.infraestructura.adaptador.persistencia.mongodb.repositorio;

import com.bsg.soporterag.infraestructura.adaptador.persistencia.mongodb.documento.CelulaRepositorioDocumento;
import org.springframework.data.mongodb.repository.ReactiveMongoRepository;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

public interface CelulaRepositorioRepositorioMongo extends ReactiveMongoRepository<CelulaRepositorioDocumento, String> {

    Flux<CelulaRepositorioDocumento> findByCodigoCelula(String codigoCelula);

    Flux<CelulaRepositorioDocumento> findByNombreRepo(String nombreRepo);

    Mono<Void> deleteByCodigoCelulaAndNombreRepo(String codigoCelula, String nombreRepo);

    Mono<Void> deleteAllByNombreRepo(String nombreRepo);

    Mono<Long> countByNombreRepo(String nombreRepo);
}
