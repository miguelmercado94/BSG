package com.bsg.soporterag.infraestructura.adaptador.persistencia.mongodb;

import com.bsg.soporterag.dominio.modelo.DocumentoSoporte;
import com.bsg.soporterag.dominio.puerto.salida.AlmacenDocumentoPort;
import com.bsg.soporterag.infraestructura.adaptador.persistencia.mongodb.mapper.DocumentoSoporteDocumentoMapper;
import com.bsg.soporterag.infraestructura.adaptador.persistencia.mongodb.repositorio.DocumentoSoporteRepositorioMongo;
import org.springframework.stereotype.Component;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

@Component
public class AlmacenDocumentoMongoAdaptador implements AlmacenDocumentoPort {

    private final DocumentoSoporteRepositorioMongo repositorio;
    private final DocumentoSoporteDocumentoMapper mapper;

    public AlmacenDocumentoMongoAdaptador(
            DocumentoSoporteRepositorioMongo repositorio,
            DocumentoSoporteDocumentoMapper mapper) {
        this.repositorio = repositorio;
        this.mapper = mapper;
    }

    @Override
    public Mono<DocumentoSoporte> guardar(DocumentoSoporte documento) {
        return repositorio.save(mapper.aDocumento(documento)).map(mapper::aDominio);
    }

    @Override
    public Mono<DocumentoSoporte> buscarPorId(String id) {
        return repositorio.findById(id).map(mapper::aDominio);
    }

    @Override
    public Mono<DocumentoSoporte> buscarPorCodigo(String codigoSoporte) {
        return repositorio.findByCodigoSoporte(codigoSoporte).map(mapper::aDominio);
    }

    @Override
    public Flux<DocumentoSoporte> listarPorUrlRepo(String urlRepo) {
        return repositorio.findByUrlRepo(urlRepo).map(mapper::aDominio);
    }

    @Override
    public Mono<Void> eliminarPorCodigo(String codigoSoporte) {
        return repositorio.deleteByCodigoSoporte(codigoSoporte);
    }
}
