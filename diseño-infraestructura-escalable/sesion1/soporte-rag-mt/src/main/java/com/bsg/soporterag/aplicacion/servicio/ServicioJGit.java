package com.bsg.soporterag.aplicacion.servicio;

import com.bsg.soporterag.dominio.modelo.CambiosEntreCommitsGit;
import com.bsg.soporterag.dominio.modelo.InfoArchivoGit;
import com.bsg.soporterag.dominio.modelo.InventarioRepositorioGit;
import com.bsg.soporterag.dominio.modelo.RamaGit;
import com.bsg.soporterag.dominio.modelo.Repositorio;
import com.bsg.soporterag.dominio.modelo.RutasRepositorioGit;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.util.List;
import java.util.Map;

/**
 * Servicios de aplicación sobre repositorios Git remotos (solo consulta vía {@link com.bsg.soporterag.dominio.puerto.salida.RepositorioGitPort}).
 */
public interface ServicioJGit {

    /**
     * Árbol del tip de {@code rama}: listas {@code filesPath} y {@code folderPath}.
     */
    Mono<RutasRepositorioGit> extraerArbolRutas(String urlRepo, String rama);

    /**
     * Contenido binario de un archivo en el tip de {@code rama} (para indexación en memoria).
     */
    Mono<byte[]> extraerContenidoArchivo(String urlRepo, String rama, String filePath);

    Mono<byte[]> extraerContenidoArchivoEnCommit(String urlRepo, String commitHash, String filePath);

    /**
     * SHA del último commit en el remoto para {@code rama} (validar frente al commit en BD).
     */
    Mono<String> obtenerUltimoCommit(String urlRepo, String rama);

    /**
     * Rama efectiva: la solicitada o la principal del remoto si viene vacía.
     */
    Mono<String> resolverRama(String urlRepo, String ramaOpcional);

    /**
     * Rutas relativas que cambiaron entre {@code commitViejo} y {@code commitNuevo} en {@code rama}.
     */
    Mono<CambiosEntreCommitsGit> listarRutasCambiadas(
            String urlRepo, String rama, String commitViejo, String commitNuevo);

    /**
     * Alta/actualización: conecta, resuelve rama, commit tip y árbol de rutas.
     */
    Mono<InventarioRepositorioGit> inventariar(Repositorio repositorio);

    Flux<RamaGit> extraerRamas(String urlRepo);

    Mono<InfoArchivoGit> extraerInfoArchivo(String urlRepo, String rama, String filePath);

    Mono<Map<RamaGit, List<InfoArchivoGit>>> consultarRamasYArchivos(String urlRepo, List<String> rutasArchivos);
}
