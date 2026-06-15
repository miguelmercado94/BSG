package com.bsg.soporterag.aplicacion.servicio.impl;

import com.bsg.soporterag.aplicacion.servicio.DocumentoSoporteServicio;
import com.bsg.soporterag.dominio.modelo.DocumentoSoporte;
import com.bsg.soporterag.dominio.puerto.salida.AlmacenDocumentoPort;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

@Service
public class DocumentoSoporteServicioImpl implements DocumentoSoporteServicio {

    private final AlmacenDocumentoPort almacenDocumentoPort;

    public DocumentoSoporteServicioImpl(AlmacenDocumentoPort almacenDocumentoPort) {
        this.almacenDocumentoPort = almacenDocumentoPort;
    }

    @Override
    public Mono<DocumentoSoporte> crear(DocumentoSoporte documento) {
        return almacenDocumentoPort.guardar(documento);
    }

    @Override
    public Mono<DocumentoSoporte> actualizar(String codigoSoporte, DocumentoSoporte documentoActualizado) {
        return almacenDocumentoPort.buscarPorCodigo(codigoSoporte)
                .flatMap(existente -> {
                    DocumentoSoporte modificado = new DocumentoSoporte(
                            existente.id(),
                            existente.codigoSoporte(),
                            documentoActualizado.urlRepo() != null ? documentoActualizado.urlRepo() : existente.urlRepo(),
                            documentoActualizado.nombre() != null ? documentoActualizado.nombre() : existente.nombre(),
                            documentoActualizado.descripcion() != null ? documentoActualizado.descripcion() : existente.descripcion(),
                            documentoActualizado.namespaceVectorial() != null ? documentoActualizado.namespaceVectorial() : existente.namespaceVectorial(),
                            documentoActualizado.urlBucketS3() != null ? documentoActualizado.urlBucketS3() : existente.urlBucketS3(),
                            documentoActualizado.bucketRol() != null ? documentoActualizado.bucketRol() : existente.bucketRol(),
                            documentoActualizado.indexado(),
                            documentoActualizado.actualizadoEn() != null ? documentoActualizado.actualizadoEn() : existente.actualizadoEn()
                    );
                    return almacenDocumentoPort.guardar(modificado);
                })
                .switchIfEmpty(Mono.error(new IllegalArgumentException("No se encontró el documento de soporte con código: " + codigoSoporte)));
    }

    @Override
    public Mono<DocumentoSoporte> obtenerPorCodigo(String codigoSoporte) {
        if (!StringUtils.hasText(codigoSoporte)) {
            return Mono.error(new IllegalArgumentException("El código del soporte es obligatorio"));
        }
        return almacenDocumentoPort.buscarPorCodigo(codigoSoporte.trim())
                .switchIfEmpty(Mono.error(new IllegalArgumentException("No se encontró el documento de soporte con código: " + codigoSoporte)));
    }

    @Override
    public Flux<DocumentoSoporte> obtenerTodosPorUrlRepo(String urlRepo) {
        if (!StringUtils.hasText(urlRepo)) {
            return Flux.error(new IllegalArgumentException("La URL del repositorio es obligatoria"));
        }
        return almacenDocumentoPort.listarPorUrlRepo(urlRepo.trim());
    }

    @Override
    public Mono<Void> eliminar(String codigoSoporte) {
        if (!StringUtils.hasText(codigoSoporte)) {
            return Mono.error(new IllegalArgumentException("El código del soporte es obligatorio"));
        }
        return almacenDocumentoPort.eliminarPorCodigo(codigoSoporte.trim());
    }
}
