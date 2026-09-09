package com.bsg.soporterag.infraestructura.adaptador.persistencia.mongodb;

import com.bsg.soporterag.dominio.modelo.MensajeChat;
import com.bsg.soporterag.dominio.modelo.Tarea;
import com.bsg.soporterag.dominio.puerto.salida.TareaRepositorioPort;
import com.bsg.soporterag.infraestructura.adaptador.persistencia.mongodb.documento.TareaDocumento;
import com.bsg.soporterag.infraestructura.adaptador.persistencia.mongodb.mapper.TareaDocumentoMapper;
import com.bsg.soporterag.infraestructura.adaptador.persistencia.mongodb.repositorio.TareaRepositorioMongo;
import org.springframework.data.mongodb.core.ReactiveMongoTemplate;
import org.springframework.data.mongodb.core.query.Criteria;
import org.springframework.data.mongodb.core.query.Query;
import org.springframework.data.mongodb.core.query.Update;
import org.springframework.stereotype.Component;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

@Component
public class TareaMongoAdaptador implements TareaRepositorioPort {

    private final TareaRepositorioMongo repositorioMongo;
    private final ReactiveMongoTemplate mongoTemplate;
    private final TareaDocumentoMapper mapper;

    public TareaMongoAdaptador(
            TareaRepositorioMongo repositorioMongo, 
            ReactiveMongoTemplate mongoTemplate, 
            TareaDocumentoMapper mapper) {
        this.repositorioMongo = repositorioMongo;
        this.mongoTemplate = mongoTemplate;
        this.mapper = mapper;
    }

    @Override
    public Mono<Tarea> guardar(Tarea tarea) {
        return repositorioMongo.save(mapper.aDocumento(tarea))
                .map(mapper::aDominio);
    }

    @Override
    public Mono<Tarea> buscarPorId(String id) {
        return repositorioMongo.findById(id)
                .map(mapper::aDominio);
    }

    @Override
    public Mono<Tarea> buscarPorCodigo(String codigoTarea) {
        return repositorioMongo.findByCodigoTarea(codigoTarea)
                .map(mapper::aDominio);
    }

    @Override
    public Flux<Tarea> buscarPorUrlRepo(String urlRepo) {
        return repositorioMongo.findByUrlRepo(urlRepo)
                .map(mapper::aDominio);
    }

    @Override
    public Flux<Tarea> buscarPorCodigoUsuario(String codigoUsuario) {
        return repositorioMongo.findByCodigoUsuario(codigoUsuario)
                .map(mapper::aDominio);
    }

    @Override
    public Mono<Void> eliminar(String id) {
        return repositorioMongo.deleteById(id);
    }

    @Override
    public Mono<Void> agregarMensajeChat(String codigoTarea, MensajeChat mensaje) {
        Query query = new Query(Criteria.where("codigo_tarea").is(codigoTarea));
        Update update = new Update().push("msg_chat", mapper.mensajeChatADocumento(mensaje));
        return mongoTemplate.updateFirst(query, update, TareaDocumento.class).then();
    }
}
