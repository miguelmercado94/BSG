package com.bsg.docviz.git;

import java.io.IOException;
import java.nio.file.Path;
import java.util.List;

/**
 * Operaciones Git de bajo nivel usadas por {@link com.bsg.docviz.service.GitRepositoryService}.
 * Implementación: JGit (Java puro).
 */
public interface GitEngine {

    /**
     * Clona en {@code parentDir}/{@code folderName} sin checkout de blobs masivos al working tree.
     * La URL puede llevar credenciales incrustadas (HTTPS).
     */
    Path cloneMetadataOnly(Path parentDir, String cloneUrl, String folderName) throws IOException;

    boolean isInsideWorkTree(Path dir) throws IOException;

    /** Especificación de revisión para listar (p. ej. HEAD, origin/main). */
    String resolveListingRevision(Path repoRoot) throws IOException;

    List<String> listTrackedFilePaths(Path repoRoot, String revisionSpec) throws IOException;

    long blobSizeBytes(Path repoRoot, String revisionSpec, String repoRelativePath) throws IOException;

    void checkoutPath(Path repoRoot, String revisionSpec, String repoRelativePath) throws IOException;

    byte[] readBlob(Path repoRoot, String revisionSpec, String repoRelativePath) throws IOException;

    /** Config local y limpieza best-effort de commit-graph sueltos (mitigación I/O). */
    void applyRepoMitigations(Path repoRoot) throws IOException;
}
