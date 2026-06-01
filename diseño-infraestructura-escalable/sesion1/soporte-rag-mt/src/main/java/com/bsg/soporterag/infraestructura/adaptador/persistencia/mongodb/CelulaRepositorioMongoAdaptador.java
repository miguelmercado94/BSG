package com.bsg.soporterag.infraestructura.adaptador.persistencia.mongodb;

import com.bsg.soporterag.dominio.modelo.AsociacionCelulaRepositorio;
import com.bsg.soporterag.dominio.puerto.salida.CelulaRepositorioPort;
import com.bsg.soporterag.infraestructura.adaptador.persistencia.mongodb.documento.CelulaRepositorioDocumento;
import com.bsg.soporterag.infraestructura.adaptador.persistencia.mongodb.repositorio.CelulaRepositorioRepositorioMongo;
import org.springframework.stereotype.Component;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

@Component
public class CelulaRepositorioMongoAdaptador implements CelulaRepositorioPort {

    private final CelulaRepositorioRepositorioMongo repositorioMongo;

    public CelulaRepositorioMongoAdaptador(CelulaRepositorioRepositorioMongo repositorioMongo) {
        this.repositorioMongo = repositorioMongo;
    }

    @Override
    public Flux<String> listarNombresRepoPorCodigoCelula(String codigoCelula) {
        return repositorioMongo.findByCodigoCelula(codigoCelula)
                .map(CelulaRepositorioDocumento::getNombreRepo);
    }

    @Override
    public Flux<String> listarCodigosCelulaPorNombreRepo(String nombreRepo) {
        return repositorioMongo.findByNombreRepo(nombreRepo)
                .map(CelulaRepositorioDocumento::getCodigoCelula);
    }

    @Override
    public Mono<AsociacionCelulaRepositorio> guardarAsociacion(AsociacionCelulaRepositorio asociacion) {
        CelulaRepositorioDocumento documento = new CelulaRepositorioDocumento();
        documento.setCodigoCelula(asociacion.getCodigoCelula());
        documento.setNombreRepo(asociacion.getNombreRepo());
        
        return repositorioMongo.save(documento)
                .map(doc -> new AsociacionCelulaRepositorio(doc.getId(), doc.getCodigoCelula(), doc.getNombreRepo()));
    }

    @Override
    public Mono<Void> eliminarAsociacion(String codigoCelula, String nombreRepo) {
        return repositorioMongo.deleteByCodigoCelulaAndNombreRepo(codigoCelula, nombreRepo);
    }

    @Override
    public Mono<Void> eliminarTodasAsociacionesPorRepo(String nombreRepo) {
        return repositorioMongo.deleteAllByNombreRepo(nombreRepo);
    }

    @Override
    public Mono<Long> contarAsociacionesPorRepo(String nombreRepo) {
        return repositorioMongo.countByNombreRepo(nombreRepo);
    }
}
