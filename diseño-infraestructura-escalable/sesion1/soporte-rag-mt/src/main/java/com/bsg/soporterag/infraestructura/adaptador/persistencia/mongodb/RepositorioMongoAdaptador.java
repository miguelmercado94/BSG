package com.bsg.soporterag.infraestructura.adaptador.persistencia.mongodb;

import com.bsg.soporterag.dominio.modelo.Repositorio;
import com.bsg.soporterag.dominio.puerto.salida.RepositorioRepositorioPort;
import com.bsg.soporterag.infraestructura.adaptador.persistencia.mongodb.documento.RepositorioDocumento;
import com.bsg.soporterag.infraestructura.adaptador.persistencia.mongodb.mapper.RepositorioDocumentoMapper;
import com.bsg.soporterag.infraestructura.adaptador.persistencia.mongodb.repositorio.RepositorioRepositorioMongo;
import org.springframework.data.mongodb.core.ReactiveMongoTemplate;
import org.springframework.data.mongodb.core.query.Criteria;
import org.springframework.data.mongodb.core.query.Query;
import org.springframework.data.mongodb.core.query.Update;
import org.springframework.stereotype.Component;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

@Component
public class RepositorioMongoAdaptador implements RepositorioRepositorioPort {

    private final RepositorioRepositorioMongo repositorioMongo;
    private final ReactiveMongoTemplate mongoTemplate;
    private final RepositorioDocumentoMapper mapper;

    public RepositorioMongoAdaptador(
            RepositorioRepositorioMongo repositorioMongo,
            ReactiveMongoTemplate mongoTemplate,
            RepositorioDocumentoMapper mapper) {
        this.repositorioMongo = repositorioMongo;
        this.mongoTemplate = mongoTemplate;
        this.mapper = mapper;
    }

    @Override
    public Mono<Repositorio> guardar(Repositorio repositorio) {
        return repositorioMongo.save(mapper.aDocumento(repositorio)).map(mapper::aDominio);
    }

    @Override
    public Mono<Repositorio> buscarPorUrl(String url) {
        return repositorioMongo.findByUrlRepo(url).map(mapper::aDominio);
    }

    @Override
    public Mono<Repositorio> buscarPorNombre(String nombreRepo) {
        return repositorioMongo.findByNombreRepo(nombreRepo).map(mapper::aDominio);
    }

    @Override
    public Flux<Repositorio> buscarPorTag(String nombreTag) {
        return repositorioMongo.findByTagsContains(nombreTag).map(mapper::aDominio);
    }

    @Override
    public Mono<Boolean> existePorUrl(String url) {
        return repositorioMongo.findByUrlRepo(url).hasElement();
    }

    @Override
    public Mono<Void> eliminar(Repositorio repositorio) {
        return repositorioMongo.delete(mapper.aDocumento(repositorio)).then();
    }

    @Override
    public Mono<Long> desasociarTagDeTodos(String nombreTag) {
        Query query = new Query(Criteria.where("tags").is(nombreTag));
        Update update = new Update().pull("tags", nombreTag);
        return mongoTemplate.updateMulti(query, update, RepositorioDocumento.class)
                .map(result -> result.getModifiedCount());
    }
}
