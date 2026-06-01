package com.bsg.soporterag.dominio.puerto.salida;

import com.bsg.soporterag.dominio.modelo.CambiosEntreCommitsGit;
import com.bsg.soporterag.dominio.modelo.RutasRepositorioGit;
import reactor.core.publisher.Mono;

/**
 * Puerto de salida Git <strong>solo consulta</strong> (RAG). No expone operaciones de escritura
 * en el remoto (push, commit, tag, branch delete, etc.).
 */
public interface RepositorioGitPort {

    /** Comprueba que el remoto responde ({@code git ls-remote}). */
    Mono<Boolean> conectar(String repositorioUrl);

    /** Rama por defecto del remoto (símbolo HEAD). */
    Mono<String> extraerRamaPrincipal(String repositorioUrl);

    /** SHA del tip de {@code rama} en el remoto ({@code ls-remote}, sin clonar). */
    Mono<String> extraerUltimoCommit(String repositorioUrl, String rama);

    /** Árbol de rutas en el tip de {@code rama} (clone local temporal + lectura de objetos). */
    Mono<RutasRepositorioGit> extraerRutas(String repositorioUrl, String rama);

    /** Contenido binario de un archivo en el tip de {@code rama} (solo lectura de blob). */
    Mono<byte[]> extraerContenidoArchivo(String repositorioUrl, String rama, String rutaArchivo);

    /**
     * Rutas que difieren entre dos commits ya existentes en el historial (lectura + diff local).
     * No modifica el repositorio remoto.
     */
    Mono<CambiosEntreCommitsGit> extraerRutasCambiadas(
            String repositorioUrl, String rama, String commitViejo, String commitNuevo);
}
