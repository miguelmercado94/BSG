package com.bsg.soporterag.aplicacion.mapperdto;

import com.bsg.soporterag.aplicacion.dto.request.CelulaRequestDto;
import com.bsg.soporterag.aplicacion.dto.response.CelulaResponseDto;
import com.bsg.soporterag.dominio.modelo.Celula;
import org.springframework.stereotype.Component;

import java.util.stream.Collectors;

@Component
public class CelulaMapperDto {

    private final RepositorioMapperDto repositorioMapperDto;

    public CelulaMapperDto(RepositorioMapperDto repositorioMapperDto) {
        this.repositorioMapperDto = repositorioMapperDto;
    }

    public Celula aDominio(CelulaRequestDto request) {
        if (request == null) {
            return null;
        }
        Celula celula = new Celula();
        celula.setCodigo(request.getCodigo());
        celula.setNombre(request.getNombre());
        celula.setDescripcion(request.getDescripcion());
        return celula;
    }

    public CelulaResponseDto aResponse(Celula celula) {
        if (celula == null) {
            return null;
        }
        CelulaResponseDto dto = new CelulaResponseDto();
        dto.setCodigo(celula.getCodigo());
        dto.setNombre(celula.getNombre());
        dto.setDescripcion(celula.getDescripcion());
        
        if (celula.getRepositorios() != null) {
            dto.setRepositorios(celula.getRepositorios().stream()
                    .map(repositorioMapperDto::aResponse)
                    .collect(Collectors.toSet()));
        }
        return dto;
    }
    
    public void actualizarDominio(Celula celula, CelulaRequestDto request) {
        if (request.getNombre() != null) {
            celula.setNombre(request.getNombre());
        }
        if (request.getDescripcion() != null) {
            celula.setDescripcion(request.getDescripcion());
        }
        // El código no se debería actualizar generalmente, pero si es necesario:
        // if (request.getCodigo() != null) {
        //     celula.setCodigo(request.getCodigo());
        // }
    }
}