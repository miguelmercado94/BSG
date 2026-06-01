package com.bsg.soporterag.infraestructura.adaptador.persistencia.mongodb.repositorio;

import com.bsg.soporterag.infraestructura.adaptador.persistencia.mongodb.documento.CelulaDocumento;
import org.springframework.data.mongodb.repository.ReactiveMongoRepository;
import reactor.core.publisher.Mono;

public interface CelulaRepositorioMongo extends ReactiveMongoRepository<CelulaDocumento, String> {
    Mono<CelulaDocumento> findByCodigoCelula(String codigo);
}