package com.bsg.soporterag.infraestructura.adaptador.persistencia.mongodb.mapper;

import com.bsg.soporterag.dominio.modelo.Repositorio;
import com.bsg.soporterag.infraestructura.adaptador.persistencia.mongodb.documento.RepositorioDocumento;
import org.springframework.stereotype.Component;

import java.util.ArrayList;

/**
 * Mapeo {@link Repositorio} ↔ {@link RepositorioDocumento} (Mongo).
 */
@Component
public class RepositorioDocumentoMapper {

    public Repositorio aDominio(RepositorioDocumento documento) {
        if (documento == null) {
            return null;
        }
        Repositorio dominio = new Repositorio();
        dominio.setId(documento.getId());
        dominio.setNombre(documento.getNombreRepo());
        dominio.setDescripcion(documento.getDescripcionRepo());
        dominio.setUrl(documento.getUrlRepo());
        dominio.setFilesPath(documento.getFilesPath() != null
                ? new ArrayList<>(documento.getFilesPath())
                : new ArrayList<>());
        dominio.setFolderPath(documento.getFolderPath() != null
                ? new ArrayList<>(documento.getFolderPath())
                : new ArrayList<>());
        dominio.setIndexado(documento.isIndexado());
        dominio.setFechaActualizacion(documento.getFechaActualizacion());
        dominio.setRamaPrincipal(documento.getRamaPrincipal());
        dominio.setUltimoCommit(documento.getUltimoCommit());
        dominio.setUrlFolderS3Workarea(documento.getUrlFolderS3Workarea());
        return dominio;
    }

    public RepositorioDocumento aDocumento(Repositorio dominio) {
        if (dominio == null) {
            return null;
        }
        RepositorioDocumento documento = new RepositorioDocumento();
        documento.setId(dominio.getId());
        documento.setNombreRepo(dominio.getNombre());
        documento.setDescripcionRepo(dominio.getDescripcion());
        documento.setUrlRepo(dominio.getUrl());
        documento.setFilesPath(dominio.getFilesPath() != null
                ? new ArrayList<>(dominio.getFilesPath())
                : new ArrayList<>());
        documento.setFolderPath(dominio.getFolderPath() != null
                ? new ArrayList<>(dominio.getFolderPath())
                : new ArrayList<>());
        documento.setIndexado(dominio.isIndexado());
        documento.setFechaActualizacion(dominio.getFechaActualizacion());
        documento.setRamaPrincipal(dominio.getRamaPrincipal());
        documento.setUltimoCommit(dominio.getUltimoCommit());
        documento.setUrlFolderS3Workarea(dominio.getUrlFolderS3Workarea());
        return documento;
    }
}
