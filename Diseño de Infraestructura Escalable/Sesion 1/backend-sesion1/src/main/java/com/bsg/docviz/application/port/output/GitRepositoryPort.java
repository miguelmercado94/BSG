package com.bsg.docviz.application.port.output;

import com.bsg.docviz.dto.FileContentResponse;
import com.bsg.docviz.dto.FolderStructureDto;
import com.bsg.docviz.dto.GitConnectRequest;
import com.bsg.docviz.dto.TreeNodeDto;

import java.io.IOException;
import java.nio.file.Path;
import java.util.List;

/**
 * Operaciones Git y conexión al clon (adaptador principal hacia {@link com.bsg.docviz.git.GitEngine}).
 */
public interface GitRepositoryPort {

    String resolveRevisionForListing(Path repoRoot);

    TreeNodeDto loadDirectoryTree(Path repoRoot, String revisionSpec);

    long objectSizeBytes(Path repoRoot, String revisionSpec, String repoRelativePath);

    void materializeFileToWorkingTree(Path repoRoot, String revisionSpec, String repoRelativePath);

    byte[] readBytesFromWorkingTree(Path repoRoot, String repoRelativePath);

    byte[] materializeAndReadBytes(Path repoRoot, String revisionSpec, String repoRelativePath);

    void deleteMaterializedFileIfPresent(Path repoRoot, String repoRelativePath);

    byte[] readBlob(Path repoRoot, String revisionSpec, String repoRelativePath);

    void connect(GitConnectRequest req);

    FolderStructureDto loadEphemeralFolderStructure(GitConnectRequest req);

    FileContentResponse loadEphemeralFileContent(GitConnectRequest req, String relativePath);

    List<String> listTrackedFiles(Path repoRoot, String revisionSpec) throws IOException, InterruptedException;

    void disconnectCleanup();
}
