package com.bsg.soporterag.infraestructura.adaptador.persistencia.mongodb;

import com.bsg.soporterag.dominio.modelo.Repositorio;
import com.bsg.soporterag.dominio.puerto.salida.RepositorioRepositorioPort;
import com.bsg.soporterag.infraestructura.adaptador.persistencia.mongodb.mapper.RepositorioDocumentoMapper;
import com.bsg.soporterag.infraestructura.adaptador.persistencia.mongodb.repositorio.RepositorioRepositorioMongo;
import org.springframework.stereotype.Component;
import reactor.core.publisher.Mono;

@Component
public class RepositorioMongoAdaptador implements RepositorioRepositorioPort {

    private final RepositorioRepositorioMongo repositorioMongo;
    private final RepositorioDocumentoMapper mapper;

    public RepositorioMongoAdaptador(
            RepositorioRepositorioMongo repositorioMongo,
            RepositorioDocumentoMapper mapper) {
        this.repositorioMongo = repositorioMongo;
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
    public Mono<Boolean> existePorUrl(String url) {
        return repositorioMongo.findByUrlRepo(url).hasElement();
    }

    @Override
    public Mono<Void> eliminar(Repositorio repositorio) {
        return repositorioMongo.delete(mapper.aDocumento(repositorio)).then();
    }
}
