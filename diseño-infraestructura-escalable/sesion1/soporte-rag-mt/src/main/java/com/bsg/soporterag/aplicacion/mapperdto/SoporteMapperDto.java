package com.bsg.soporterag.aplicacion.mapperdto;

import com.bsg.soporterag.aplicacion.dto.request.CrearSoporteRequestDto;
import com.bsg.soporterag.aplicacion.dto.response.SoporteResponseDto;
import com.bsg.soporterag.dominio.modelo.DocumentoSoporte;
import com.bsg.soporterag.dominio.modelo.Repositorio;
import com.bsg.soporterag.dominio.modelo.RolBucketS3;
import org.springframework.stereotype.Component;

import java.time.Instant;

@Component
public class SoporteMapperDto {

    public DocumentoSoporte aDominio(CrearSoporteRequestDto request, Repositorio repositorio, String s3Path) {
        return new DocumentoSoporte(
                null, // id
                request.getCodigo(),
                repositorio.getUrl(),
                request.getNombre(),
                request.getDescripcion(),
                repositorio.getNamespace() != null ? repositorio.getNamespace() : repositorio.getUrl(),
                s3Path, // La ruta completa calculada en el caso de uso
                RolBucketS3.WORKAREA,
                false, // No indexado al crear
                Instant.now()
        );
    }

    public SoporteResponseDto aResponse(DocumentoSoporte dominio, String urlRepo) {
        SoporteResponseDto dto = new SoporteResponseDto();
        dto.setCodigo(dominio.codigoSoporte());
        dto.setNombre(dominio.nombre());
        dto.setDescripcion(dominio.descripcion());
        dto.setUrlRepo(urlRepo);
        dto.setUrlS3(dominio.urlBucketS3());
        // El contenido en base64 se deja nulo intencionalmente en la respuesta
        return dto;
    }
}
