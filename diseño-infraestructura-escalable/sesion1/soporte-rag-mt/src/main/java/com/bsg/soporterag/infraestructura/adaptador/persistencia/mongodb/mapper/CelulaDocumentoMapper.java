package com.bsg.soporterag.infraestructura.adaptador.persistencia.mongodb.mapper;

import com.bsg.soporterag.dominio.modelo.Celula;
import com.bsg.soporterag.infraestructura.adaptador.persistencia.mongodb.documento.CelulaDocumento;
import org.springframework.stereotype.Component;

@Component
public class CelulaDocumentoMapper {

    public Celula aDominio(CelulaDocumento documento) {
        if (documento == null) {
            return null;
        }
        Celula dominio = new Celula();
        dominio.setId(documento.getId());
        dominio.setCodigo(documento.getCodigoCelula());
        dominio.setNombre(documento.getNombreCelula());
        dominio.setDescripcion(documento.getDescripcionCelula());
        return dominio;
    }

    public CelulaDocumento aDocumento(Celula dominio) {
        if (dominio == null) {
            return null;
        }
        CelulaDocumento documento = new CelulaDocumento();
        documento.setId(dominio.getId());
        documento.setCodigoCelula(dominio.getCodigo());
        documento.setNombreCelula(dominio.getNombre());
        documento.setDescripcionCelula(dominio.getDescripcion());
        return documento;
    }
}