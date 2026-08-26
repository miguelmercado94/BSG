package com.bsg.soporterag.infraestructura.adaptador.persistencia.mongodb.mapper;

import com.bsg.soporterag.dominio.modelo.Repositorio;
import com.bsg.soporterag.infraestructura.adaptador.persistencia.mongodb.documento.RepositorioDocumento;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.Collections;
import java.util.stream.Collectors;

/**
 * Mapeo {@link Repositorio} ↔ {@link RepositorioDocumento} (Mongo).
 */
@Component
public class RepositorioDocumentoMapper {

    private final TagDocumentoMapper tagMapper;

    public RepositorioDocumentoMapper(TagDocumentoMapper tagMapper) {
        this.tagMapper = tagMapper;
    }

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
        if (documento.getNamespace() != null) {
            dominio.setNamespace(documento.getNamespace());
        } else {
            String base = documento.getNombreRepo().replaceAll("[^a-zA-Z0-9._-]", "_").replaceAll("_+", "_");
            dominio.setNamespace(base + "-" + java.util.UUID.randomUUID().toString());
        }
        
        if (documento.getTags() != null) {
            dominio.setTags(new ArrayList<>(documento.getTags()));
        } else {
            dominio.setTags(Collections.emptyList());
        }

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
        documento.setNamespace(dominio.getNamespace());

        if (dominio.getTags() != null) {
            documento.setTags(new ArrayList<>(dominio.getTags()));
        } else {
            documento.setTags(Collections.emptyList());
        }

        return documento;
    }
}
