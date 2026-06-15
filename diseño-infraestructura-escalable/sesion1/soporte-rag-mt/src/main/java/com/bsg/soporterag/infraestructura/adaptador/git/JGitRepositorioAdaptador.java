package com.bsg.soporterag.infraestructura.adaptador.git;

import com.bsg.soporterag.dominio.modelo.CambiosEntreCommitsGit;
import com.bsg.soporterag.dominio.modelo.CommitGit;
import com.bsg.soporterag.dominio.modelo.InfoArchivoGit;
import com.bsg.soporterag.dominio.modelo.RamaGit;
import com.bsg.soporterag.dominio.modelo.RutasRepositorioGit;
import com.bsg.soporterag.dominio.puerto.salida.RepositorioGitPort;
import org.eclipse.jgit.api.Git;
import org.eclipse.jgit.api.ListBranchCommand;
import org.eclipse.jgit.api.errors.GitAPIException;
import org.eclipse.jgit.diff.DiffEntry;
import org.eclipse.jgit.diff.DiffFormatter;
import org.eclipse.jgit.lib.Constants;
import org.eclipse.jgit.lib.FileMode;
import org.eclipse.jgit.lib.ObjectId;
import org.eclipse.jgit.lib.ObjectLoader;
import org.eclipse.jgit.lib.Ref;
import org.eclipse.jgit.lib.Repository;
import org.eclipse.jgit.revwalk.RevCommit;
import org.eclipse.jgit.revwalk.RevWalk;
import org.eclipse.jgit.treewalk.TreeWalk;
import org.eclipse.jgit.util.io.DisabledOutputStream;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;
import reactor.core.scheduler.Scheduler;

import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.TreeSet;

public class JGitRepositorioAdaptador implements RepositorioGitPort {

    private final Scheduler gitScheduler;

    public JGitRepositorioAdaptador(Scheduler gitScheduler) {
        this.gitScheduler = gitScheduler;
    }

    // ... otros métodos ...

    @Override
    public Mono<byte[]> extraerContenidoArchivoEnCommit(String repositorioUrl, String commitHash, String rutaArchivo) {
        return Mono.fromCallable(() -> {
            try (SesionGit sesion = abrirSesionCompletaBare(repositorioUrl)) {
                ObjectId commitId = sesion.repo().resolve(commitHash);
                if (commitId == null) {
                    throw new IllegalArgumentException("No se pudo resolver el commit: " + commitHash);
                }
                return leerBlobEnCommit(sesion.repo(), commitId, rutaArchivo);
            }
        }).subscribeOn(gitScheduler);
    }

    @Override
    public Mono<Map<RamaGit, List<InfoArchivoGit>>> consultarRamasYArchivos(String repositorioUrl, List<String> rutasArchivos) {
        return Mono.fromCallable(() -> {
            Map<RamaGit, List<InfoArchivoGit>> resultadoFinal = new HashMap<>();
            try (SesionGit sesion = abrirSesionCompletaBare(repositorioUrl)) {
                Repository repo = sesion.repo();
                List<Ref> branches = sesion.git().branchList().setListMode(ListBranchCommand.ListMode.REMOTE).call();
                
                for (Ref ref : branches) {
                    String nombreRama = Repository.shortenRefName(ref.getName());
                    if (nombreRama.startsWith("origin/")) {
                        nombreRama = nombreRama.substring("origin/".length());
                        if ("HEAD".equals(nombreRama)) continue;
                    }

                    try (RevWalk walk = new RevWalk(repo)) {
                        RevCommit ultimoCommitRama = walk.parseCommit(ref.getObjectId());
                        RamaGit ramaGit = new RamaGit(nombreRama, new CommitGit(ultimoCommitRama.getName(), ultimoCommitRama.getShortMessage(), ultimoCommitRama.getAuthorIdent().getName()));
                        
                        List<InfoArchivoGit> infos = new ArrayList<>();
                        if (rutasArchivos != null && !rutasArchivos.isEmpty()) {
                            for (String ruta : rutasArchivos) {
                                infos.add(getInfoArchivoEnCommit(repo, ultimoCommitRama, ruta));
                            }
                        }
                        resultadoFinal.put(ramaGit, infos);
                    }
                }
            }
            return resultadoFinal;
        })
        .subscribeOn(gitScheduler);
    }

    private InfoArchivoGit getInfoArchivoEnCommit(Repository repo, RevCommit commit, String rutaArchivo) throws IOException {
        try (TreeWalk treeWalk = TreeWalk.forPath(repo, rutaArchivo, commit.getTree())) {
            if (treeWalk == null) {
                return new InfoArchivoGit(rutaArchivo, false, null);
            }
            // Si existe, buscamos su último commit
            try (RevWalk revWalk = new RevWalk(repo)) {
                Iterable<RevCommit> logs = new Git(repo).log().add(commit.getId()).addPath(rutaArchivo).setMaxCount(1).call();
                for (RevCommit logCommit : logs) {
                    return new InfoArchivoGit(rutaArchivo, true, new CommitGit(logCommit.getName(), logCommit.getShortMessage(), logCommit.getAuthorIdent().getName()));
                }
            } catch (GitAPIException e) {
                // Fallback si el log falla
                return new InfoArchivoGit(rutaArchivo, true, null);
            }
        }
        return new InfoArchivoGit(rutaArchivo, false, null);
    }
    
    // ... resto de métodos ...
    @Override
    public Mono<Boolean> conectar(String repositorioUrl) {
        return Mono.fromCallable(() -> {
                    try {
                        return !Git.lsRemoteRepository()
                                .setRemote(repositorioUrl)
                                .call()
                                .isEmpty();
                    } catch (GitAPIException e) {
                        return false;
                    }
                })
                .subscribeOn(gitScheduler);
    }

    @Override
    public Mono<String> extraerRamaPrincipal(String repositorioUrl) {
        return Mono.fromCallable(() -> {
                    Map<String, Ref> refs = Git.lsRemoteRepository()
                            .setRemote(repositorioUrl)
                            .callAsMap();
                    Ref head = refs.get(Constants.HEAD);
                    if (head != null && head.isSymbolic()) {
                        return Repository.shortenRefName(head.getTarget().getName());
                    }
                    return "main";
                })
                .subscribeOn(gitScheduler)
                .onErrorMap(GitAPIException.class, e ->
                        new IllegalStateException("Error al obtener la rama principal", e));
    }

    @Override
    public Mono<String> extraerUltimoCommit(String repositorioUrl, String rama) {
        return Mono.fromCallable(() -> resolverTipRemoto(repositorioUrl, rama))
                .subscribeOn(gitScheduler)
                .onErrorMap(GitAPIException.class, e ->
                        new IllegalStateException("Error al obtener el último commit", e));
    }

    @Override
    public Mono<RutasRepositorioGit> extraerRutas(String repositorioUrl, String rama) {
        return Mono.fromCallable(() -> {
                    try (SesionGit sesion = abrirSesion(repositorioUrl, rama, 1)) {
                        ObjectId head = sesion.repo().resolve("HEAD");
                        if (head == null) throw new IllegalStateException("No se resolvio HEAD");
                        return listarRutasEnCommit(sesion.repo(), head);
                    }
                })
                .subscribeOn(gitScheduler);
    }

    @Override
    public Mono<byte[]> extraerContenidoArchivo(String repositorioUrl, String rama, String rutaArchivo) {
        return Mono.fromCallable(() -> {
                    try (SesionGit sesion = abrirSesion(repositorioUrl, rama, 1)) {
                        ObjectId head = sesion.repo().resolve("HEAD");
                        if (head == null) throw new IllegalStateException("No se resolvio HEAD");
                        return leerBlobEnCommit(sesion.repo(), head, rutaArchivo);
                    }
                })
                .subscribeOn(gitScheduler);
    }

    @Override
    public Mono<CambiosEntreCommitsGit> extraerRutasCambiadas(
            String repositorioUrl, String rama, String commitViejo, String commitNuevo) {
        return Mono.fromCallable(() -> {
                    try (SesionGit sesion = abrirSesion(repositorioUrl, rama, 1)) {
                        ObjectId oldId = descargarCommitParaLectura(sesion, commitViejo);
                        ObjectId newId = descargarCommitParaLectura(sesion, commitNuevo);
                        return diffRutas(sesion.repo(), oldId, newId);
                    }
                })
                .subscribeOn(gitScheduler);
    }

    @Override
    public Flux<RamaGit> extraerRamas(String repositorioUrl) {
        return Mono.fromCallable(() -> {
            List<RamaGit> ramas = new ArrayList<>();
            // Clon superficial de todas las ramas para leer el último commit de cada una
            try (SesionGit sesion = abrirSesionTodasLasRamas(repositorioUrl)) {
                Repository repo = sesion.repo();
                List<Ref> branches = sesion.git().branchList().setListMode(ListBranchCommand.ListMode.ALL).call();
                try (RevWalk walk = new RevWalk(repo)) {
                    for (Ref ref : branches) {
                        String name = Repository.shortenRefName(ref.getName());
                        if (name.startsWith("origin/")) {
                            name = name.substring("origin/".length());
                            if ("HEAD".equals(name)) continue;
                            
                            RevCommit commit = walk.parseCommit(ref.getObjectId());
                            ramas.add(new RamaGit(
                                name, 
                                new CommitGit(commit.getName(), commit.getShortMessage(), commit.getAuthorIdent().getName())
                            ));
                        }
                    }
                }
            }
            return ramas;
        })
        .subscribeOn(gitScheduler)
        .flatMapMany(Flux::fromIterable);
    }

    @Override
    public Mono<InfoArchivoGit> extraerInfoArchivo(String repositorioUrl, String rama, String rutaArchivo) {
        return Mono.fromCallable(() -> {
            // Necesitamos historial para usar git log, así que clone completo pero bare
            try (SesionGit sesion = abrirSesionCompletaBare(repositorioUrl)) {
                Repository repo = sesion.repo();
                ObjectId head = repo.resolve("refs/remotes/origin/" + rama);
                if (head == null) return new InfoArchivoGit(rutaArchivo, false, null);

                // Comprobar si el archivo existe en ese commit
                boolean existe = false;
                try (RevWalk walk = new RevWalk(repo)) {
                    RevCommit commit = walk.parseCommit(head);
                    try (TreeWalk treeWalk = TreeWalk.forPath(repo, rutaArchivo, commit.getTree())) {
                        existe = treeWalk != null;
                    }
                }

                if (!existe) {
                    return new InfoArchivoGit(rutaArchivo, false, null);
                }

                // Encontrar el último commit que lo modificó
                Iterable<RevCommit> logs = sesion.git().log()
                        .add(head)
                        .addPath(rutaArchivo)
                        .setMaxCount(1)
                        .call();

                for (RevCommit commit : logs) {
                    return new InfoArchivoGit(
                        rutaArchivo, 
                        true, 
                        new CommitGit(commit.getName(), commit.getShortMessage(), commit.getAuthorIdent().getName())
                    );
                }

                return new InfoArchivoGit(rutaArchivo, true, null);
            }
        })
        .subscribeOn(gitScheduler);
    }

    private static String resolverTipRemoto(String repositorioUrl, String rama) throws GitAPIException {
        Map<String, Ref> refs = Git.lsRemoteRepository()
                .setRemote(repositorioUrl)
                .callAsMap();
        Ref ref = refs.get(Constants.R_HEADS + rama);
        if (ref == null || ref.getObjectId() == null) {
            throw new IllegalArgumentException("Rama no existe");
        }
        return ref.getObjectId().getName();
    }

    private SesionGit abrirSesion(String repositorioUrl, String rama, int depth) throws GitAPIException, IOException {
        Path tempDir = Files.createTempDirectory("jgit-");
        Git git = Git.cloneRepository()
                .setURI(repositorioUrl)
                .setDirectory(tempDir.toFile())
                .setBranch(rama)
                .setCloneAllBranches(false)
                .setDepth(depth)
                .call();
        return new SesionGit(git, tempDir);
    }

    private SesionGit abrirSesionTodasLasRamas(String repositorioUrl) throws GitAPIException, IOException {
        Path tempDir = Files.createTempDirectory("jgit-");
        Git git = Git.cloneRepository()
                .setURI(repositorioUrl)
                .setDirectory(tempDir.toFile())
                .setCloneAllBranches(true)
                .setDepth(1) // Solo necesitamos el tip de cada rama
                .call();
        return new SesionGit(git, tempDir);
    }

    private SesionGit abrirSesionCompletaBare(String repositorioUrl) throws GitAPIException, IOException {
        Path tempDir = Files.createTempDirectory("jgit-bare-");
        Git git = Git.cloneRepository()
                .setURI(repositorioUrl)
                .setDirectory(tempDir.toFile())
                .setBare(true) // Bare repo, no working tree
                .setCloneAllBranches(true)
                .call();
        return new SesionGit(git, tempDir);
    }

    private ObjectId descargarCommitParaLectura(SesionGit sesion, String commitSha) throws GitAPIException, IOException {
        Repository repo = sesion.repo();
        ObjectId id = repo.resolve(commitSha);
        if (id != null) return id;
        sesion.git().fetch()
                .setRemote("origin")
                .setRefSpecs(new org.eclipse.jgit.transport.RefSpec("+" + commitSha + ":refs/jgit-fetch/" + commitSha))
                .call();
        id = repo.resolve(commitSha);
        if (id == null) id = repo.resolve("refs/jgit-fetch/" + commitSha);
        if (id == null) throw new IllegalArgumentException("No se resolvió el commit");
        return id;
    }

    private static RutasRepositorioGit listarRutasEnCommit(Repository repo, ObjectId commitId) throws IOException {
        Set<String> files = new TreeSet<>();
        Set<String> folders = new TreeSet<>();
        try (RevWalk walk = new RevWalk(repo)) {
            RevCommit commit = walk.parseCommit(commitId);
            try (TreeWalk treeWalk = new TreeWalk(repo)) {
                treeWalk.addTree(commit.getTree());
                treeWalk.setRecursive(true);
                while (treeWalk.next()) {
                    String path = treeWalk.getPathString();
                    if (path == null || path.isBlank() || debeOmitirRuta(path)) continue;
                    FileMode mode = treeWalk.getFileMode(0);
                    if (mode == FileMode.TREE || mode == FileMode.GITLINK) {
                        folders.add(path);
                    } else if (mode == FileMode.REGULAR_FILE || mode == FileMode.EXECUTABLE_FILE || mode == FileMode.SYMLINK) {
                        files.add(path);
                        agregarCarpetasPadre(path, folders);
                    }
                }
            }
        }
        return new RutasRepositorioGit(new ArrayList<>(files), new ArrayList<>(folders));
    }

    private static byte[] leerBlobEnCommit(Repository repo, ObjectId commitId, String rutaArchivo) throws IOException {
        try (RevWalk walk = new RevWalk(repo)) {
            RevCommit commit = walk.parseCommit(commitId);
            try (TreeWalk treeWalk = TreeWalk.forPath(repo, rutaArchivo, commit.getTree())) {
                if (treeWalk == null) throw new IllegalArgumentException("Archivo no existe");
                ObjectId blobId = treeWalk.getObjectId(0);
                ObjectLoader loader = repo.open(blobId);
                return loader.getBytes();
            }
        }
    }

    private static CambiosEntreCommitsGit diffRutas(Repository repo, ObjectId oldId, ObjectId newId) throws IOException {
        List<String> agregadas = new ArrayList<>();
        List<String> modificadas = new ArrayList<>();
        List<String> eliminadas = new ArrayList<>();
        try (RevWalk walk = new RevWalk(repo)) {
            RevCommit oldCommit = walk.parseCommit(oldId);
            RevCommit newCommit = walk.parseCommit(newId);
            try (DiffFormatter formatter = new DiffFormatter(DisabledOutputStream.INSTANCE)) {
                formatter.setRepository(repo);
                formatter.setDetectRenames(true);
                for (DiffEntry entry : formatter.scan(oldCommit.getTree(), newCommit.getTree())) {
                    String ruta = rutaDesdeDiff(entry);
                    if (ruta == null || ruta.isBlank() || debeOmitirRuta(ruta)) continue;
                    switch (entry.getChangeType()) {
                        case ADD, COPY -> agregadas.add(ruta);
                        case MODIFY -> modificadas.add(ruta);
                        case DELETE -> eliminadas.add(ruta);
                        case RENAME -> {
                            if (entry.getNewPath() != null && !DiffEntry.DEV_NULL.equals(entry.getNewPath())) agregadas.add(entry.getNewPath());
                            if (entry.getOldPath() != null && !DiffEntry.DEV_NULL.equals(entry.getOldPath())) eliminadas.add(entry.getOldPath());
                        }
                        default -> {}
                    }
                }
            }
        }
        return new CambiosEntreCommitsGit(agregadas, modificadas, eliminadas);
    }

    private static String rutaDesdeDiff(DiffEntry entry) {
        if (entry.getChangeType() == DiffEntry.ChangeType.DELETE) return entry.getOldPath();
        return entry.getNewPath();
    }

    private static void agregarCarpetasPadre(String filePath, Set<String> folders) {
        int slash = filePath.lastIndexOf('/');
        while (slash > 0) {
            folders.add(filePath.substring(0, slash));
            slash = filePath.lastIndexOf('/', slash - 1);
        }
    }

    private static boolean debeOmitirRuta(String path) {
        return path.startsWith(".git/") || path.equals(".git");
    }

    private static void limpiarCopiaLocalTemporal(File directorio) {
        File[] archivos = directorio.listFiles();
        if (archivos != null) {
            for (File archivo : archivos) {
                limpiarCopiaLocalTemporal(archivo);
            }
        }
        directorio.delete();
    }

    private record SesionGit(Git git, Path tempDir) implements AutoCloseable {
        Repository repo() {
            return git.getRepository();
        }
        @Override
        public void close() {
            git.close();
            limpiarCopiaLocalTemporal(tempDir.toFile());
        }
    }
}
