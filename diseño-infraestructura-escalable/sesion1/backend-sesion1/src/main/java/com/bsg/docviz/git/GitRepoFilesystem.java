package com.bsg.docviz.git;

import java.io.IOException;
import java.nio.file.FileVisitResult;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.SimpleFileVisitor;
import java.nio.file.attribute.BasicFileAttributes;

/**
 * Operaciones de fichero bajo {@code .git} compartidas entre motores Git.
 */
public final class GitRepoFilesystem {

    private GitRepoFilesystem() {}

    public static void deleteDirectoryRecursive(Path root) throws IOException {
        if (root == null || !Files.exists(root)) {
            return;
        }
        Files.walkFileTree(root, new SimpleFileVisitor<>() {
            @Override
            public FileVisitResult visitFile(Path file, BasicFileAttributes attrs) throws IOException {
                Files.deleteIfExists(file);
                return FileVisitResult.CONTINUE;
            }

            @Override
            public FileVisitResult postVisitDirectory(Path dir, IOException exc) throws IOException {
                Files.deleteIfExists(dir);
                return FileVisitResult.CONTINUE;
            }
        });
    }

    /**
     * El grafo de commits es opcional; en OneDrive/Windows a veces queda bloqueado. Borrar deja que Git siga sin él.
     */
    public static void tryDeleteLooseCommitGraph(Path repoRoot) {
        try {
            Path info = repoRoot.resolve(".git/objects/info");
            if (!Files.isDirectory(info)) {
                return;
            }
            Files.deleteIfExists(info.resolve("commit-graph"));
            Path graphs = info.resolve("commit-graphs");
            if (Files.isDirectory(graphs)) {
                try (var stream = Files.list(graphs)) {
                    for (Path p : stream.toList()) {
                        Files.deleteIfExists(p);
                    }
                }
            }
        } catch (IOException | RuntimeException ignored) {
            // best effort
        }
    }
}
