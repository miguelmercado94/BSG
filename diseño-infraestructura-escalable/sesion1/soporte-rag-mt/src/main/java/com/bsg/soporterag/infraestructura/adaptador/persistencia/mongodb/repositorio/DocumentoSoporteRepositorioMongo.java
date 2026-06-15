package com.bsg.soporterag.infraestructura.adaptador.persistencia.mongodb.repositorio;

import com.bsg.soporterag.infraestructura.adaptador.persistencia.mongodb.documento.DocumentoSoporteDocumento;
import org.springframework.data.mongodb.repository.ReactiveMongoRepository;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

public interface DocumentoSoporteRepositorioMongo extends ReactiveMongoRepository<DocumentoSoporteDocumento, String> {

    Mono<DocumentoSoporteDocumento> findByCodigoSoporte(String codigoSoporte);

    Flux<DocumentoSoporteDocumento> findByNamespaceVectorial(String namespaceVectorial);

    Flux<DocumentoSoporteDocumento> findByUrlRepo(String urlRepo);

    Mono<Void> deleteByCodigoSoporte(String codigoSoporte);
}
