package com.bsg.soporterag.infraestructura.adaptador.persistencia.mongodb;

import com.bsg.soporterag.dominio.modelo.Tag;
import com.bsg.soporterag.dominio.modelo.UrlToolTag;
import com.bsg.soporterag.dominio.puerto.salida.TagRepositorioPort;
import com.bsg.soporterag.infraestructura.adaptador.persistencia.mongodb.documento.TagDocumento;
import com.bsg.soporterag.infraestructura.adaptador.persistencia.mongodb.mapper.TagDocumentoMapper;
import com.bsg.soporterag.infraestructura.adaptador.persistencia.mongodb.repositorio.TagRepositorioMongo;
import org.springframework.data.mongodb.core.ReactiveMongoTemplate;
import org.springframework.data.mongodb.core.query.Criteria;
import org.springframework.data.mongodb.core.query.Query;
import org.springframework.data.mongodb.core.query.Update;
import org.springframework.stereotype.Component;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.util.List;

@Component
public class TagMongoAdaptador implements TagRepositorioPort {

    private final TagRepositorioMongo tagRepositorioMongo;
    private final ReactiveMongoTemplate mongoTemplate;
    private final TagDocumentoMapper tagMapper;

    public TagMongoAdaptador(
            TagRepositorioMongo tagRepositorioMongo,
            ReactiveMongoTemplate mongoTemplate, 
            TagDocumentoMapper tagMapper) {
        this.tagRepositorioMongo = tagRepositorioMongo;
        this.mongoTemplate = mongoTemplate;
        this.tagMapper = tagMapper;
    }

    @Override
    public Mono<Tag> guardar(Tag tag) {
        return tagRepositorioMongo.save(tagMapper.aDocumento(tag))
                .map(tagMapper::aDominio);
    }

    @Override
    public Flux<Tag> buscarPorTags(String... nombresTags) {
        if (nombresTags == null || nombresTags.length == 0) {
            return Flux.empty();
        }
        if (nombresTags.length == 1) {
            return tagRepositorioMongo.findByTag(nombresTags[0]).map(tagMapper::aDominio).flux();
        }
        return tagRepositorioMongo.findByTagIn(List.of(nombresTags))
                .map(tagMapper::aDominio);
    }

    @Override
    public Flux<Tag> buscarTodos() {
        return tagRepositorioMongo.findAll()
                .map(tagMapper::aDominio);
    }

    @Override
    public Mono<Void> eliminarPorTag(String nombreTag) {
        return tagRepositorioMongo.deleteByTag(nombreTag);
    }

    @Override
    public Mono<Void> agregarUrlTool(String nombreTag, UrlToolTag urlTool) {
        Query query = new Query(Criteria.where("tag").is(nombreTag));
        Update update = new Update().push("url_tool_tag", tagMapper.urlToolTagADocumento(urlTool));
        return mongoTemplate.updateFirst(query, update, TagDocumento.class).then();
    }

    @Override
    public Mono<Void> eliminarUrlTool(String nombreTag, String urlTool) {
        Query query = new Query(Criteria.where("tag").is(nombreTag));
        Update update = new Update().pull("url_tool_tag", Query.query(Criteria.where("url_tool").is(urlTool)));
        return mongoTemplate.updateFirst(query, update, TagDocumento.class).then();
    }
}
