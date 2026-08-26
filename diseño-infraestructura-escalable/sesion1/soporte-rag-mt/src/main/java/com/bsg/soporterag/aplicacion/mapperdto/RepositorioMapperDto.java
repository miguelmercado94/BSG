package com.bsg.soporterag.aplicacion.mapperdto;

import com.bsg.soporterag.aplicacion.dto.request.RepositorioRequestDto;
import com.bsg.soporterag.aplicacion.dto.response.RepositorioResponseDto;
import com.bsg.soporterag.dominio.modelo.InventarioRepositorioGit;
import com.bsg.soporterag.dominio.modelo.Repositorio;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;

import java.time.Instant;

/**
 * Mapeo exclusivo DTO (API) ↔ {@link Repositorio} (dominio).
 * <p>
 * No mapea documentos Mongo; eso es {@code RepositorioDocumentoMapper} en infraestructura.
 */
@Component
public class RepositorioMapperDto {

    public Repositorio aDominioDesdeRequest(RepositorioRequestDto request, String urlNormalizada) {
        Repositorio repositorio = new Repositorio();
        String nombre = request.getNombre().trim();
        repositorio.setNombre(nombre);
        repositorio.setUrl(urlNormalizada);
        repositorio.setDescripcion(request.getDescripcion());
        repositorio.setIndexado(false);
        repositorio.setFechaActualizacion(Instant.now());
        repositorio.setUrlFolderS3Workarea(prefijoWorkareaS3(nombre));
        if (StringUtils.hasText(request.getRamaPrincipal())) {
            repositorio.setRamaPrincipal(request.getRamaPrincipal().trim());
        }
        return repositorio;
    }

    /** Prefijo de carpeta en bucket workarea: {@code /nombre-repo/}. */
    public static String prefijoWorkareaS3(String nombreRepo) {
        return "/" + nombreRepo.trim() + "/";
    }

    public void aplicarArbolRutas(Repositorio repositorio, com.bsg.soporterag.dominio.modelo.RutasRepositorioGit rutas) {
        if (rutas.filesPath() != null) {
            repositorio.setFilesPath(rutas.filesPath());
        }
        if (rutas.folderPath() != null) {
            repositorio.setFolderPath(rutas.folderPath());
        }
    }

    /** Campos editables del request (la URL la valida {@link com.bsg.soporterag.aplicacion.servicio.RepositorioServicio}). */
    public void aplicarRequestParcial(Repositorio repositorio, RepositorioRequestDto request) {
        if (StringUtils.hasText(request.getNombre())) {
            repositorio.setNombre(request.getNombre().trim());
        }
        if (StringUtils.hasText(request.getDescripcion())) {
            repositorio.setDescripcion(request.getDescripcion());
        }
        if (StringUtils.hasText(request.getRamaPrincipal())) {
            repositorio.setRamaPrincipal(request.getRamaPrincipal().trim());
        }
    }

    /** Vista mínima de dominio para consultar Git (url + rama) sin persistir aún. */
    public Repositorio aDominioParaConsultaGit(
            Repositorio existente, RepositorioRequestDto request, String urlConsulta) {
        Repositorio consulta = new Repositorio();
        consulta.setUrl(urlConsulta);
        consulta.setRamaPrincipal(
                StringUtils.hasText(request.getRamaPrincipal())
                        ? request.getRamaPrincipal().trim()
                        : existente.getRamaPrincipal());
        return consulta;
    }

    public void aplicarInventarioGit(Repositorio repositorio, InventarioRepositorioGit inventario) {
        repositorio.setRamaPrincipal(inventario.ramaPrincipal());
        repositorio.setUltimoCommit(inventario.ultimoCommit());
        if (inventario.filesPath() != null) {
            repositorio.setFilesPath(inventario.filesPath());
        }
        if (inventario.folderPath() != null) {
            repositorio.setFolderPath(inventario.folderPath());
        }
        repositorio.setFechaActualizacion(Instant.now());
    }

    public RepositorioResponseDto aResponse(Repositorio repositorio) {
        RepositorioResponseDto dto = new RepositorioResponseDto();
        dto.setNombre(repositorio.getNombre());
        dto.setUrl(repositorio.getUrl());
        dto.setRamaPrincipal(repositorio.getRamaPrincipal());
        dto.setUltimoCommit(repositorio.getUltimoCommit());
        dto.setDescripcion(repositorio.getDescripcion());
        dto.setIndexado(repositorio.isIndexado());
        dto.setUrlFolderS3Workarea(repositorio.getUrlFolderS3Workarea());
        dto.setFilesPath(repositorio.getFilesPath());
        dto.setFolderPath(repositorio.getFolderPath());
        dto.setVectorNamespace(repositorio.getNamespace());
        dto.setTags(repositorio.getTags() != null ? repositorio.getTags() : java.util.List.of());
        return dto;
    }
}