package com.bsg.docviz.service;

import com.bsg.docviz.application.port.output.GitRepositoryPort;
import com.bsg.docviz.application.port.output.SessionRegistryPort;
import com.bsg.docviz.config.DocvizProperties;
import com.bsg.docviz.dto.FileContentResponse;
import com.bsg.docviz.dto.FolderStructureDto;
import com.bsg.docviz.dto.FolderStructureMapper;
import com.bsg.docviz.dto.GitConnectionMode;
import com.bsg.docviz.dto.GitConnectRequest;
import com.bsg.docviz.dto.TreeNodeDto;
import com.bsg.docviz.git.GitEngine;
import com.bsg.docviz.git.GitRepoFilesystem;
import com.bsg.docviz.security.CurrentUser;
import com.bsg.docviz.util.FileTreeBuilder;
import com.bsg.docviz.util.RepoPathExclude;
import com.bsg.docviz.util.RepositoryUrlNormalizer;
import com.bsg.docviz.util.SourceTextExtractor;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;
import java.util.Locale;
import java.util.Optional;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;

@Service
public class GitRepositoryService implements GitRepositoryPort {

    private static final int VECTOR_NS_MAX = 500;

    /**
     * Una operación Git a la vez por directorio de trabajo (mismo .git). En Windows varias llamadas en
     * paralelo (ingesta + RAG + vista) chocan con {@code .git/objects/maintenance.lock}.
     */
    private final ConcurrentHashMap<String, Object> repoGitLocks = new ConcurrentHashMap<>();

    /** Evita repetir mitigaciones por la misma ruta canónica. */
    private final Set<String> mitigatedRepoKeys = ConcurrentHashMap.newKeySet();

    private static IllegalStateException wrapGitIOException(IOException e) {
        String m = e.getMessage() == null ? e.getClass().getSimpleName() : e.getMessage();
        String lower = m.toLowerCase(Locale.ROOT);
        String msg = "Git I/O error: " + m;
        if (lower.contains("pack") || lower.contains("onedrive") || lower.contains(".idx")) {
            msg +=
                    " — Suele ocurrir con clones bajo OneDrive o carpetas sincronizadas. Define DOCVIZ_CONTEXT_MASTERS_BASE_PATH "
                            + "(o docviz.context-masters.base-path) en una ruta fija fuera de la nube (p. ej. C:/docviz/context-masters), "
                            + "reinicia el backend y borra la carpeta vieja bajo context-masters si el clon quedó corrupto.";
        }
        return new IllegalStateException(msg, e);
    }

    private final SessionRegistryPort sessionRegistry;
    private final DocvizProperties docvizProperties;
    private final GitEngine gitEngine;

    public GitRepositoryService(
            SessionRegistryPort sessionRegistry, DocvizProperties docvizProperties, GitEngine gitEngine) {
        this.sessionRegistry = sessionRegistry;
        this.docvizProperties = docvizProperties;
        this.gitEngine = gitEngine;
    }

    @FunctionalInterface
    private interface IoSupplier<T> {
        T get() throws IOException;
    }

    /**
     * Serializa operaciones Git por repo y reintenta errores transitorios de bloqueo (Windows / OneDrive).
     */
    private <T> T executeWithGitLock(Path repoRoot, IoSupplier<T> supplier) throws IOException, InterruptedException {
        String key = canonicalRepoKey(repoRoot);
        Object lockObj = repoGitLocks.computeIfAbsent(key, k -> new Object());
        synchronized (lockObj) {
            ensureRepoMitigations(repoRoot, key);
            int attempt = 0;
            while (true) {
                try {
                    return supplier.get();
                } catch (IOException e) {
                    attempt++;
                    if (attempt >= 8 || !isTransientGitLockIOException(e)) {
                        throw e;
                    }
                    GitRepoFilesystem.tryDeleteLooseCommitGraph(repoRoot);
                    try {
                        Thread.sleep(100L * attempt);
                    } catch (InterruptedException ie) {
                        Thread.currentThread().interrupt();
                        throw e;
                    }
                }
            }
        }
    }

    private void executeVoidWithGitLock(Path repoRoot, IoSupplier<Void> supplier) throws IOException, InterruptedException {
        executeWithGitLock(
                repoRoot,
                () -> {
                    supplier.get();
                    return null;
                });
    }

    public String resolveRevisionForListing(Path repoRoot) {
        try {
            return resolveRevisionForListingInternal(repoRoot);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new IllegalStateException("Git operation interrupted", e);
        } catch (IOException e) {
            throw wrapGitIOException(e);
        }
    }

    public TreeNodeDto loadDirectoryTree(Path repoRoot, String revisionSpec) {
        try {
            List<String> paths = listTrackedFiles(repoRoot, revisionSpec);
            return FileTreeBuilder.fromPaths(paths);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new IllegalStateException("Git operation interrupted", e);
        } catch (IOException e) {
            throw wrapGitIOException(e);
        }
    }

    public long objectSizeBytes(Path repoRoot, String revisionSpec, String repoRelativePath) {
        try {
            String rel = normalizeRepoRelativePath(repoRelativePath);
            return executeWithGitLock(repoRoot, () -> gitEngine.blobSizeBytes(repoRoot, revisionSpec, rel));
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new IllegalStateException("Git operation interrupted", e);
        } catch (IOException e) {
            throw wrapGitIOException(e);
        }
    }

    /**
     * Descarga un único archivo (blob bajo demanda) y lo deja en el working tree: solo cuando hace
     * falta visualizar, indexar en Pinecone o RAG — no el repo completo.
     */
    public void materializeFileToWorkingTree(Path repoRoot, String revisionSpec, String repoRelativePath) {
        try {
            String rel = normalizeRepoRelativePath(repoRelativePath);
            executeVoidWithGitLock(
                    repoRoot,
                    () -> {
                        gitEngine.checkoutPath(repoRoot, revisionSpec, rel);
                        return null;
                    });
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new IllegalStateException("Git operation interrupted", e);
        } catch (IOException e) {
            throw wrapGitIOException(e);
        }
    }

    public byte[] readBytesFromWorkingTree(Path repoRoot, String repoRelativePath) {
        try {
            String rel = normalizeRepoRelativePath(repoRelativePath);
            Path root = repoRoot.toAbsolutePath().normalize();
            Path file = root.resolve(rel).normalize();
            if (!file.startsWith(root)) {
                throw new IllegalArgumentException("invalid path");
            }
            if (!Files.isRegularFile(file)) {
                throw new IllegalStateException("archivo no materializado en disco: " + rel);
            }
            return Files.readAllBytes(file);
        } catch (IOException e) {
            throw new IllegalStateException("I/O: " + e.getMessage(), e);
        }
    }

    /**
     * {@link #materializeFileToWorkingTree} y luego lectura desde el working tree (mismo flujo que ingesta Pinecone).
     */
    public byte[] materializeAndReadBytes(Path repoRoot, String revisionSpec, String repoRelativePath) {
        materializeFileToWorkingTree(repoRoot, revisionSpec, repoRelativePath);
        return readBytesFromWorkingTree(repoRoot, repoRelativePath);
    }

    /**
     * Quita el archivo del working tree tras haberlo leído a memoria; evita acumular todo el repo en disco
     * en el microservicio. No usar con {@code localPath} del usuario (solo clones efímeros).
     */
    public void deleteMaterializedFileIfPresent(Path repoRoot, String repoRelativePath) {
        try {
            String rel = normalizeRepoRelativePath(repoRelativePath);
            Path root = repoRoot.toAbsolutePath().normalize();
            Path file = root.resolve(rel).normalize();
            if (!file.startsWith(root)) {
                return;
            }
            Files.deleteIfExists(file);
        } catch (IOException ignored) {
            // best effort
        }
    }

    public byte[] readBlob(Path repoRoot, String revisionSpec, String repoRelativePath) {
        try {
            String rel = normalizeRepoRelativePath(repoRelativePath);
            return executeWithGitLock(repoRoot, () -> gitEngine.readBlob(repoRoot, revisionSpec, rel));
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new IllegalStateException("Git operation interrupted", e);
        } catch (IOException e) {
            throw wrapGitIOException(e);
        }
    }

    private static String normalizeRepoRelativePath(String repoRelativePath) {
        if (repoRelativePath == null || repoRelativePath.isBlank()) {
            throw new IllegalArgumentException("path required");
        }
        String p = repoRelativePath.replace('\\', '/').trim();
        if (p.startsWith("/")) {
            p = p.substring(1);
        }
        if (p.contains("..")) {
            throw new IllegalArgumentException("invalid path");
        }
        return p;
    }

    public void connect(GitConnectRequest req) {
        try {
            connectInternal(req);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new IllegalStateException("Git operation interrupted", e);
        } catch (IOException e) {
            throw wrapGitIOException(e);
        }
    }

    private record EphemeralRepoRoots(Path root, Path managedCloneRoot) {}

    private EphemeralRepoRoots prepareEphemeralRoots(GitConnectRequest req) throws IOException, InterruptedException {
        Path root;
        Path managedCloneRoot;
        switch (req.getMode()) {
            case LOCAL -> {
                if (req.getLocalPath() == null || req.getLocalPath().isBlank()) {
                    throw new IllegalArgumentException("localPath is required for LOCAL mode");
                }
                root = Path.of(req.getLocalPath()).toAbsolutePath().normalize();
                if (!Files.isDirectory(root)) {
                    throw new IllegalArgumentException("localPath is not a directory");
                }
                verifyGitRepo(root);
                managedCloneRoot = null;
            }
            case HTTPS_PUBLIC -> {
                if (req.getRepositoryUrl() == null || req.getRepositoryUrl().isBlank()) {
                    throw new IllegalArgumentException("repositoryUrl is required");
                }
                String pubUrl = req.getRepositoryUrl().trim();
                if (!pubUrl.toLowerCase().startsWith("https://")) {
                    throw new IllegalArgumentException("repositoryUrl must use https://");
                }
                root = cloneMetadataOnly(pubUrl, slugFromGitUrl(pubUrl));
                managedCloneRoot = root;
            }
            case HTTPS_AUTH -> {
                if (req.getRepositoryUrl() == null || req.getRepositoryUrl().isBlank()) {
                    throw new IllegalArgumentException("repositoryUrl is required");
                }
                if (req.getUsername() == null || req.getUsername().isBlank()
                        || req.getToken() == null || req.getToken().isBlank()) {
                    throw new IllegalArgumentException("username and token are required for HTTPS_AUTH");
                }
                String url = injectHttpsCredentials(req.getRepositoryUrl().trim(), req.getUsername().trim(), req.getToken().trim());
                root = cloneMetadataOnly(url, slugFromGitUrl(req.getRepositoryUrl().trim()));
                managedCloneRoot = root;
            }
            default -> throw new IllegalArgumentException("Unsupported mode");
        }
        return new EphemeralRepoRoots(root, managedCloneRoot);
    }

    /**
     * Árbol de archivos sin persistir sesión (p. ej. administración de célula). Libera el clon HTTPS al terminar.
     */
    public FolderStructureDto loadEphemeralFolderStructure(GitConnectRequest req) {
        try {
            EphemeralRepoRoots pr = prepareEphemeralRoots(req);
            try {
                String rev = resolveRevisionForListingInternal(pr.root());
                TreeNodeDto tree = FileTreeBuilder.fromPaths(listTrackedFiles(pr.root(), rev));
                FolderStructureDto directory =
                        FolderStructureMapper.fromTreeRoot(tree, computeRootFolderLabel(req), pr.root());
                FolderStructureMapper.ensureRootFolderName(directory, pr.root());
                if (directory != null) {
                    String name = folderLabelForConnectUi(req);
                    if (name != null && !name.isBlank()) {
                        directory.setFolder(name);
                    }
                }
                return directory;
            } finally {
                if (pr.managedCloneRoot() != null) {
                    deleteRecursivelyQuietly(pr.managedCloneRoot());
                }
            }
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new IllegalStateException("Git operation interrupted", e);
        } catch (IOException e) {
            throw wrapGitIOException(e);
        }
    }

    /** Contenido de un archivo del repo (blob) sin sesión persistente. */
    public FileContentResponse loadEphemeralFileContent(GitConnectRequest req, String relativePath) {
        try {
            EphemeralRepoRoots pr = prepareEphemeralRoots(req);
            try {
                String rev = resolveRevisionForListingInternal(pr.root());
                byte[] raw = readBlob(pr.root(), rev, relativePath);
                String text = SourceTextExtractor.extractText(relativePath, raw);
                FileContentResponse out = new FileContentResponse();
                out.setPath(relativePath);
                out.setContent(text != null ? text : "");
                out.setEncoding("utf-8");
                return out;
            } finally {
                if (pr.managedCloneRoot() != null) {
                    deleteRecursivelyQuietly(pr.managedCloneRoot());
                }
            }
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new IllegalStateException("Git operation interrupted", e);
        } catch (IOException e) {
            throw wrapGitIOException(e);
        }
    }

    private static String folderLabelForConnectUi(GitConnectRequest req) {
        if (req.getMode() == GitConnectionMode.LOCAL) {
            return localRepositoryFolderName(req.getLocalPath());
        }
        String url = req.getRepositoryUrl();
        if (url == null || url.isBlank()) {
            return "";
        }
        String name = url.substring(url.lastIndexOf('/') + 1);
        return name.endsWith(".git") ? name.substring(0, name.length() - 4) : name;
    }

    private void connectInternal(GitConnectRequest req) throws IOException, InterruptedException {
        UserRepositoryState st = sessionRegistry.current();

        EphemeralRepoRoots pr = prepareEphemeralRoots(req);
        Path root = pr.root();
        Path managedCloneRoot = pr.managedCloneRoot();

        String rev = resolveRevisionForListingInternal(root);
        TreeNodeDto tree;
        try {
            tree = FileTreeBuilder.fromPaths(listTrackedFiles(root, rev));
        } catch (IOException | InterruptedException e) {
            if (managedCloneRoot != null) {
                deleteRecursivelyQuietly(managedCloneRoot);
            }
            if (e instanceof InterruptedException) {
                Thread.currentThread().interrupt();
            }
            throw e;
        }

        Optional<Path> previous = st.drainManagedCloneRoot();
        st.disconnect();
        previous.ifPresent(this::deleteRecursivelyQuietly);

        st.getViewerContentCache().clear();
        st.getIngestContentCache().clear();
        String rootFolderLabel = computeRootFolderLabel(req);
        st.setConnected(root, managedCloneRoot, rev, tree, rootFolderLabel);
        if (req.getVectorNamespace() != null && !req.getVectorNamespace().isBlank()) {
            st.setVectorNamespaceOverride(
                    RepositoryUrlNormalizer.clampNamespace(req.getVectorNamespace().trim(), VECTOR_NS_MAX));
        } else {
            st.setVectorNamespaceOverride(null);
        }
    }

    private static String computeRootFolderLabel(GitConnectRequest req) {
        return switch (req.getMode()) {
            case LOCAL -> localRepositoryFolderName(req.getLocalPath());
            case HTTPS_PUBLIC, HTTPS_AUTH -> gitStyleRepoName(req.getRepositoryUrl());
            default -> "";
        };
    }

    private static String localRepositoryFolderName(String localPath) {
        if (localPath == null || localPath.isBlank()) {
            return "";
        }
        return Path.of(localPath.trim()).getFileName().toString();
    }

    private static String gitStyleRepoName(String repositoryUrl) {
        if (repositoryUrl == null || repositoryUrl.isBlank()) {
            return "";
        }
        return slugFromGitUrl(repositoryUrl.trim());
    }

    /**
     * Clon para listar metadatos; el motor {@link GitEngine} (JGit) realiza clon sin checkout pesado
     * (JGit).
     */
    private Path cloneMetadataOnly(String cloneUrl, String folderName) throws IOException, InterruptedException {
        Path masters = docvizProperties.resolveRootDirectory();
        Path userDir = masters.resolve(CurrentUser.require());
        Files.createDirectories(userDir);
        return executeWithGitLock(userDir, () -> gitEngine.cloneMetadataOnly(userDir, cloneUrl, folderName));
    }

    /** Nombre de carpeta/repo derivado de una URL o ruta estilo Git (público para reutilizar en dominio). */
    public static String slugFromGitUrl(String repositoryUrl) {
        String u = repositoryUrl.replace('\\', '/').trim();
        int q = u.indexOf('?');
        if (q >= 0) {
            u = u.substring(0, q);
        }
        int last = u.lastIndexOf('/');
        String name = last >= 0 ? u.substring(last + 1) : u;
        if (name.endsWith(".git")) {
            name = name.substring(0, name.length() - 4);
        }
        name = name.replaceAll("[^a-zA-Z0-9._-]", "_");
        if (name.isBlank()) {
            name = "repo";
        }
        return name;
    }

    private static String injectHttpsCredentials(String httpsUrl, String username, String token) {
        String u = httpsUrl.trim();
        if (!u.toLowerCase().startsWith("https://")) {
            throw new IllegalArgumentException("repositoryUrl must use https://");
        }
        String rest = u.substring("https://".length());
        int slash = rest.indexOf('/');
        String host = slash >= 0 ? rest.substring(0, slash) : rest;
        String pathPart = slash >= 0 ? rest.substring(slash) : "";
        String encUser = urlEncodeUserPart(username);
        String encTok = urlEncodeUserPart(token);
        return "https://" + encUser + ":" + encTok + "@" + host + pathPart;
    }

    private static String urlEncodeUserPart(String value) {
        return URLEncoder.encode(value, StandardCharsets.UTF_8).replace("+", "%20");
    }

    private void deleteRecursivelyQuietly(Path root) {
        try {
            GitRepoFilesystem.deleteDirectoryRecursive(root);
        } catch (IOException e) {
            throw new IllegalStateException("Could not delete clone directory: " + e.getMessage(), e);
        }
    }

    private void verifyGitRepo(Path dir) throws IOException, InterruptedException {
        Boolean ok = executeWithGitLock(dir, () -> gitEngine.isInsideWorkTree(dir));
        if (!Boolean.TRUE.equals(ok)) {
            throw new IllegalArgumentException("localPath is not a git working tree");
        }
    }

    private String resolveRevisionForListingInternal(Path repoRoot) throws IOException, InterruptedException {
        return executeWithGitLock(repoRoot, () -> gitEngine.resolveListingRevision(repoRoot));
    }

    public List<String> listTrackedFiles(Path repoRoot, String revisionSpec) throws IOException, InterruptedException {
        List<String> lines =
                executeWithGitLock(repoRoot, () -> gitEngine.listTrackedFilePaths(repoRoot, revisionSpec));
        return RepoPathExclude.filterWorkspacePaths(lines);
    }

    private static String canonicalRepoKey(Path workingDir) {
        try {
            return workingDir.toRealPath().normalize().toString().toLowerCase(Locale.ROOT);
        } catch (IOException e) {
            return workingDir.toAbsolutePath().normalize().toString().toLowerCase(Locale.ROOT);
        }
    }

    private static boolean isTransientGitLockIOException(IOException e) {
        String m = e.getMessage();
        if (m == null) {
            return false;
        }
        String lower = m.toLowerCase(Locale.ROOT);
        return lower.contains("maintenance.lock")
                || lower.contains("commit-graph")
                || lower.contains("objects\\info")
                || lower.contains("objects/info")
                || lower.contains("being used by another process")
                || lower.contains("siendo utilizado por otro proceso")
                || lower.contains("cannot access the file")
                || lower.contains("no tiene acceso al archivo")
                || lower.contains("because it is being used")
                || lower.contains("access is denied")
                || lower.contains("acceso denegado");
    }

    private void ensureRepoMitigations(Path repoRoot, String canonicalKey) {
        if (!mitigatedRepoKeys.add(canonicalKey)) {
            return;
        }
        try {
            gitEngine.applyRepoMitigations(repoRoot);
        } catch (IOException e) {
            mitigatedRepoKeys.remove(canonicalKey);
        }
    }

    /**
     * Borra el clon HTTPS efímero (si existe) y desconecta la sesión del usuario actual.
     */
    public void disconnectCleanup() {
        UserRepositoryState st = sessionRegistry.current();
        Optional<Path> previous = st.drainManagedCloneRoot();
        st.disconnect();
        previous.ifPresent(this::deleteRecursivelyQuietly);
    }
}
