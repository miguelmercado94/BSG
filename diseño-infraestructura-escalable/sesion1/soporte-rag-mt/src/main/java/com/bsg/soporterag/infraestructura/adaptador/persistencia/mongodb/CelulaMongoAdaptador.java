package com.bsg.soporterag.infraestructura.adaptador.persistencia.mongodb;

import com.bsg.soporterag.dominio.modelo.Celula;
import com.bsg.soporterag.dominio.puerto.salida.CelulaPort;
import com.bsg.soporterag.infraestructura.adaptador.persistencia.mongodb.mapper.CelulaDocumentoMapper;
import com.bsg.soporterag.infraestructura.adaptador.persistencia.mongodb.repositorio.CelulaRepositorioMongo;
import org.springframework.stereotype.Component;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

@Component
public class CelulaMongoAdaptador implements CelulaPort {

    private final CelulaRepositorioMongo celulaRepositorioMongo;
    private final CelulaDocumentoMapper celulaDocumentoMapper;

    public CelulaMongoAdaptador(CelulaRepositorioMongo celulaRepositorioMongo, CelulaDocumentoMapper celulaDocumentoMapper) {
        this.celulaRepositorioMongo = celulaRepositorioMongo;
        this.celulaDocumentoMapper = celulaDocumentoMapper;
    }

    @Override
    public Flux<Celula> findAll() {
        return celulaRepositorioMongo.findAll().map(celulaDocumentoMapper::aDominio);
    }

    @Override
    public Mono<Celula> findById(String id) {
        return celulaRepositorioMongo.findById(id).map(celulaDocumentoMapper::aDominio);
    }

    @Override
    public Mono<Celula> findByCodigo(String codigo) {
        return celulaRepositorioMongo.findByCodigoCelula(codigo).map(celulaDocumentoMapper::aDominio);
    }

    @Override
    public Mono<Celula> save(Celula celula) {
        return celulaRepositorioMongo.save(celulaDocumentoMapper.aDocumento(celula))
                .map(celulaDocumentoMapper::aDominio);
    }

    @Override
    public Mono<Void> deleteById(String id) {
        return celulaRepositorioMongo.deleteById(id);
    }
}