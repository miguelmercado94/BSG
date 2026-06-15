package com.bsg.soporterag.aplicacion.servicio.impl;

import com.bsg.soporterag.aplicacion.servicio.ServicioJGit;
import com.bsg.soporterag.dominio.modelo.CambiosEntreCommitsGit;
import com.bsg.soporterag.dominio.modelo.InfoArchivoGit;
import com.bsg.soporterag.dominio.modelo.InventarioRepositorioGit;
import com.bsg.soporterag.dominio.modelo.RamaGit;
import com.bsg.soporterag.dominio.modelo.Repositorio;
import com.bsg.soporterag.dominio.modelo.RutasRepositorioGit;
import com.bsg.soporterag.dominio.puerto.salida.RepositorioGitPort;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.util.List;
import java.util.Map;

@Service
public class ServicioJGitImpl implements ServicioJGit {

    private final RepositorioGitPort repositorioGitPort;

    public ServicioJGitImpl(RepositorioGitPort repositorioGitPort) {
        this.repositorioGitPort = repositorioGitPort;
    }

    @Override
    public Mono<RutasRepositorioGit> extraerArbolRutas(String urlRepo, String rama) {
        return validarRemoto(normalizarUrl(urlRepo))
                .then(repositorioGitPort.extraerRutas(normalizarUrl(urlRepo), normalizarRama(rama)));
    }

    @Override
    public Mono<byte[]> extraerContenidoArchivo(String urlRepo, String rama, String filePath) {
        String url = normalizarUrl(urlRepo);
        String ruta = normalizarRutaArchivo(filePath);
        return validarRemoto(url)
                .then(repositorioGitPort.extraerContenidoArchivo(url, normalizarRama(rama), ruta));
    }

    @Override
    public Mono<byte[]> extraerContenidoArchivoEnCommit(String urlRepo, String commitHash, String filePath) {
        String url = normalizarUrl(urlRepo);
        String ruta = normalizarRutaArchivo(filePath);
        String commit = normalizarCommit(commitHash);
        return validarRemoto(url)
                .then(repositorioGitPort.extraerContenidoArchivoEnCommit(url, commit, ruta));
    }

    @Override
    public Mono<String> obtenerUltimoCommit(String urlRepo, String rama) {
        return validarRemoto(normalizarUrl(urlRepo))
                .then(repositorioGitPort.extraerUltimoCommit(normalizarUrl(urlRepo), normalizarRama(rama)));
    }

    @Override
    public Mono<String> resolverRama(String urlRepo, String ramaOpcional) {
        String url = normalizarUrl(urlRepo);
        if (StringUtils.hasText(ramaOpcional)) {
            return Mono.just(ramaOpcional.trim());
        }
        return validarRemoto(url).then(repositorioGitPort.extraerRamaPrincipal(url));
    }

    @Override
    public Mono<CambiosEntreCommitsGit> listarRutasCambiadas(
            String urlRepo, String rama, String commitViejo, String commitNuevo) {
        String url = normalizarUrl(urlRepo);
        return validarRemoto(url)
                .then(repositorioGitPort.extraerRutasCambiadas(
                        url,
                        normalizarRama(rama),
                        normalizarCommit(commitViejo),
                        normalizarCommit(commitNuevo)));
    }

    @Override
    public Mono<InventarioRepositorioGit> inventariar(Repositorio repositorio) {
        String url = normalizarUrl(repositorio.getUrl());
        return validarRemoto(url)
                .then(resolverRama(repositorio, url))
                .flatMap(rama -> Mono.zip(
                        repositorioGitPort.extraerUltimoCommit(url, rama),
                        repositorioGitPort.extraerRutas(url, rama),
                        (commit, rutas) -> new InventarioRepositorioGit(
                                rama, commit, rutas.filesPath(), rutas.folderPath())));
    }

    @Override
    public Flux<RamaGit> extraerRamas(String urlRepo) {
        String url = normalizarUrl(urlRepo);
        return validarRemoto(url)
                .thenMany(repositorioGitPort.extraerRamas(url));
    }

    @Override
    public Mono<InfoArchivoGit> extraerInfoArchivo(String urlRepo, String rama, String filePath) {
        String url = normalizarUrl(urlRepo);
        String ruta = normalizarRutaArchivo(filePath);
        String ramaNorm = normalizarRama(rama);
        return validarRemoto(url)
                .then(repositorioGitPort.extraerInfoArchivo(url, ramaNorm, ruta));
    }

    @Override
    public Mono<Map<RamaGit, List<InfoArchivoGit>>> consultarRamasYArchivos(String urlRepo, List<String> rutasArchivos) {
        String url = normalizarUrl(urlRepo);
        return validarRemoto(url)
                .then(repositorioGitPort.consultarRamasYArchivos(url, rutasArchivos));
    }

    private Mono<String> resolverRama(Repositorio repositorio, String url) {
        if (StringUtils.hasText(repositorio.getRamaPrincipal())) {
            return Mono.just(repositorio.getRamaPrincipal().trim());
        }
        return repositorioGitPort.extraerRamaPrincipal(url);
    }

    private Mono<Void> validarRemoto(String url) {
        return repositorioGitPort.conectar(url)
                .flatMap(ok -> Boolean.TRUE.equals(ok)
                        ? Mono.empty()
                        : Mono.error(new IllegalArgumentException("No se pudo conectar al repositorio remoto")));
    }

    private String normalizarUrl(String url) {
        if (!StringUtils.hasText(url)) {
            throw new IllegalArgumentException("La URL del repositorio es obligatoria");
        }
        return url.trim();
    }

    private String normalizarRama(String rama) {
        if (!StringUtils.hasText(rama)) {
            throw new IllegalArgumentException("La rama es obligatoria");
        }
        return rama.trim();
    }

    private String normalizarRutaArchivo(String filePath) {
        if (!StringUtils.hasText(filePath)) {
            throw new IllegalArgumentException("La ruta del archivo es obligatoria");
        }
        String ruta = filePath.trim().replace('\\', '/');
        if (ruta.startsWith("/")) {
            ruta = ruta.substring(1);
        }
        return ruta;
    }

    private String normalizarCommit(String commit) {
        if (!StringUtils.hasText(commit)) {
            throw new IllegalArgumentException("El identificador de commit es obligatorio");
        }
        return commit.trim();
    }
}
