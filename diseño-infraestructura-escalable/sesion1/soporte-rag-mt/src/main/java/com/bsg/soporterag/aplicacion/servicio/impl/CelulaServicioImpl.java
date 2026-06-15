package com.bsg.soporterag.aplicacion.servicio.impl;

import com.bsg.soporterag.aplicacion.servicio.CelulaServicio;
import com.bsg.soporterag.dominio.modelo.AsociacionCelulaRepositorio;
import com.bsg.soporterag.dominio.modelo.Celula;
import com.bsg.soporterag.dominio.puerto.salida.CelulaPort;
import com.bsg.soporterag.dominio.puerto.salida.CelulaRepositorioPort;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

@Service
public class CelulaServicioImpl implements CelulaServicio {

    private final CelulaRepositorioPort celulaRepositorioPort;
    private final CelulaPort celulaPort;

    public CelulaServicioImpl(CelulaRepositorioPort celulaRepositorioPort, CelulaPort celulaPort) {
        this.celulaRepositorioPort = celulaRepositorioPort;
        this.celulaPort = celulaPort;
    }

    @Override
    public Flux<Celula> listarTodas() {
        return celulaPort.findAll();
    }

    @Override
    public Mono<Celula> obtenerPorId(String id) {
        if (!StringUtils.hasText(id)) {
            return Mono.error(new IllegalArgumentException("El ID de la célula es obligatorio"));
        }
        return celulaPort.findById(id.trim());
    }

    @Override
    public Mono<Celula> obtenerPorCodigo(String codigo) {
         if (!StringUtils.hasText(codigo)) {
            return Mono.error(new IllegalArgumentException("El código de la célula es obligatorio"));
        }
        return celulaPort.findByCodigo(codigo.trim());
    }

    @Override
    public Mono<Celula> crear(Celula celula) {
        return celulaPort.save(celula);
    }

    @Override
    public Mono<Celula> actualizar(String id, Celula celula) {
        return celulaPort.findById(id)
                .flatMap(existente -> {
                    celula.setId(existente.getId());
                    return celulaPort.save(celula);
                });
    }

    @Override
    public Mono<Void> eliminar(String id) {
        if (!StringUtils.hasText(id)) {
            return Mono.error(new IllegalArgumentException("El ID de la célula es obligatorio"));
        }
        return celulaPort.deleteById(id.trim());
    }

    @Override
    public Flux<String> listarNombresRepoPorCodigoCelula(String codigoCelula) {
        if (!StringUtils.hasText(codigoCelula)) {
            return Flux.error(new IllegalArgumentException("El código de célula es obligatorio"));
        }
        return celulaRepositorioPort.listarNombresRepoPorCodigoCelula(codigoCelula.trim());
    }

    @Override
    public Flux<Celula> listarCelulasPorNombreRepo(String nombreRepo) {
        return celulaRepositorioPort.listarCodigosCelulaPorNombreRepo(nombreRepo)
                .flatMap(this::obtenerPorCodigo);
    }

    @Override
    public Mono<AsociacionCelulaRepositorio> asociarRepositorio(String codigoCelula, String nombreRepo) {
        if (!StringUtils.hasText(codigoCelula) || !StringUtils.hasText(nombreRepo)) {
            return Mono.error(new IllegalArgumentException("El código de célula y el nombre de repositorio son obligatorios"));
        }
        AsociacionCelulaRepositorio asociacion = new AsociacionCelulaRepositorio(null, codigoCelula, nombreRepo);
        return celulaRepositorioPort.guardarAsociacion(asociacion);
    }

    @Override
    public Mono<Void> desasociarRepositorio(String codigoCelula, String nombreRepo) {
        return celulaRepositorioPort.eliminarAsociacion(codigoCelula, nombreRepo);
    }

    @Override
    public Mono<Void> desasociarRepositorioDeTodasCelulas(String nombreRepo) {
        return celulaRepositorioPort.eliminarTodasAsociacionesPorRepo(nombreRepo);
    }

    @Override
    public Mono<Long> contarAsociacionesParaRepo(String nombreRepo) {
        return celulaRepositorioPort.contarAsociacionesPorRepo(nombreRepo);
    }

    @Override
    public Mono<Boolean> existeAsociacion(String codigoCelula, String nombreRepo) {
        return celulaRepositorioPort.listarNombresRepoPorCodigoCelula(codigoCelula)
                .any(repo -> repo.equals(nombreRepo));
    }
}
