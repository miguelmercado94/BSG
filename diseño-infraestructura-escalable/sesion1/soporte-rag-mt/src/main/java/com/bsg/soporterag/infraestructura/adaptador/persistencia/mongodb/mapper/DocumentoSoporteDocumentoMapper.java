package com.bsg.soporterag.infraestructura.adaptador.persistencia.mongodb.mapper;

import com.bsg.soporterag.dominio.modelo.DocumentoSoporte;
import com.bsg.soporterag.infraestructura.adaptador.persistencia.mongodb.documento.DocumentoSoporteDocumento;
import org.springframework.stereotype.Component;

@Component
public class DocumentoSoporteDocumentoMapper {

    public DocumentoSoporte aDominio(DocumentoSoporteDocumento documento) {
        if (documento == null) {
            return null;
        }
        return new DocumentoSoporte(
                documento.getId(),
                documento.getCodigoSoporte(),
                documento.getUrlRepo(),
                documento.getNombre(),
                documento.getDescripcion(),
                documento.getNamespaceVectorial(),
                documento.getUrlBucketS3(),
                documento.getBucketRol(),
                documento.isIndexado(),
                documento.getActualizadoEn());
    }

    public DocumentoSoporteDocumento aDocumento(DocumentoSoporte dominio) {
        if (dominio == null) {
            return null;
        }
        DocumentoSoporteDocumento documento = new DocumentoSoporteDocumento();
        documento.setId(dominio.id());
        documento.setUrlRepo(dominio.urlRepo());
        documento.setCodigoSoporte(dominio.codigoSoporte());
        documento.setNombre(dominio.nombre());
        documento.setDescripcion(dominio.descripcion());
        documento.setNamespaceVectorial(dominio.namespaceVectorial());
        documento.setUrlBucketS3(dominio.urlBucketS3());
        documento.setBucketRol(dominio.bucketRol());
        documento.setIndexado(dominio.indexado());
        documento.setActualizadoEn(dominio.actualizadoEn());
        return documento;
    }
}
