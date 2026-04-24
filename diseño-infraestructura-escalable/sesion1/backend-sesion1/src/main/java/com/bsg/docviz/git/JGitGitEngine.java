package com.bsg.docviz.git;

import org.eclipse.jgit.api.Git;
import org.eclipse.jgit.api.errors.GitAPIException;
import org.eclipse.jgit.lib.ObjectId;
import org.eclipse.jgit.lib.ObjectLoader;
import org.eclipse.jgit.lib.Repository;
import org.eclipse.jgit.lib.StoredConfig;
import org.eclipse.jgit.revwalk.RevCommit;
import org.eclipse.jgit.revwalk.RevWalk;
import org.eclipse.jgit.treewalk.TreeWalk;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;

/**
 * Implementación Git pura Java (sin binario {@code git}). Clon completo sin checkout de working tree;
 * no usa {@code --filter=blob:none} (comportamiento distinto al motor CLI).
 */
public class JGitGitEngine implements GitEngine {

    private static final String[] REVISION_CANDIDATES = {
        "origin/main", "origin/master", "origin/develop", "main", "master", "develop"
    };

    @Override
    public Path cloneMetadataOnly(Path parentDir, String cloneUrl, String folderName) throws IOException {
        Path targetDir = parentDir.resolve(folderName);
        GitRepoFilesystem.deleteDirectoryRecursive(targetDir);
        Files.createDirectories(parentDir);
        try {
            Git.cloneRepository()
                    .setURI(cloneUrl)
                    .setDirectory(targetDir.toFile())
                    .setNoCheckout(true)
                    .setCloneSubmodules(false)
                    .call()
                    .close();
        } catch (GitAPIException e) {
            GitRepoFilesystem.deleteDirectoryRecursive(targetDir);
            throw new IOException("git clone failed: " + e.getMessage(), e);
        }
        return targetDir;
    }

    @Override
    public boolean isInsideWorkTree(Path dir) throws IOException {
        try (Git git = Git.open(dir.toFile())) {
            Repository r = git.getRepository();
            return !r.isBare();
        } catch (IOException e) {
            return false;
        }
    }

    @Override
    public String resolveListingRevision(Path repoRoot) throws IOException {
        try (Git git = Git.open(repoRoot.toFile())) {
            Repository repo = git.getRepository();
            if (repo.resolve("HEAD") != null) {
                return "HEAD";
            }
            for (String c : REVISION_CANDIDATES) {
                if (repo.resolve(c) != null) {
                    return c;
                }
            }
        }
        throw new IOException(
                "Could not resolve a revision (HEAD, origin/main, origin/master, origin/develop, …) to list the tree");
    }

    @Override
    public List<String> listTrackedFilePaths(Path repoRoot, String revisionSpec) throws IOException {
        try (Git git = Git.open(repoRoot.toFile())) {
            Repository repo = git.getRepository();
            ObjectId commitId = repo.resolve(revisionSpec);
            if (commitId == null) {
                throw new IOException("Unknown revision: " + revisionSpec);
            }
            List<String> paths = new ArrayList<>();
            try (RevWalk rw = new RevWalk(repo)) {
                RevCommit commit = rw.parseCommit(commitId);
                try (TreeWalk treeWalk = new TreeWalk(repo)) {
                    treeWalk.addTree(commit.getTree());
                    treeWalk.setRecursive(true);
                    while (treeWalk.next()) {
                        paths.add(treeWalk.getPathString());
                    }
                }
            }
            return paths;
        }
    }

    @Override
    public long blobSizeBytes(Path repoRoot, String revisionSpec, String repoRelativePath) throws IOException {
        try (Git git = Git.open(repoRoot.toFile())) {
            return openBlobLoader(git.getRepository(), revisionSpec, repoRelativePath).getSize();
        }
    }

    @Override
    public void checkoutPath(Path repoRoot, String revisionSpec, String repoRelativePath) throws IOException {
        try (Git git = Git.open(repoRoot.toFile())) {
            git.checkout().setStartPoint(revisionSpec).addPath(repoRelativePath).call();
        } catch (GitAPIException e) {
            throw new IOException("git checkout failed: " + e.getMessage(), e);
        }
    }

    @Override
    public byte[] readBlob(Path repoRoot, String revisionSpec, String repoRelativePath) throws IOException {
        try (Git git = Git.open(repoRoot.toFile())) {
            return openBlobLoader(git.getRepository(), revisionSpec, repoRelativePath).getBytes();
        }
    }

    @Override
    public void applyRepoMitigations(Path repoRoot) throws IOException {
        try (Git git = Git.open(repoRoot.toFile())) {
            StoredConfig cfg = git.getRepository().getConfig();
            cfg.setString("maintenance", null, "auto", "false");
            cfg.setString("gc", null, "auto", "0");
            cfg.setBoolean("fetch", null, "writeCommitGraph", false);
            cfg.save();
        }
        GitRepoFilesystem.tryDeleteLooseCommitGraph(repoRoot);
    }

    private static ObjectLoader openBlobLoader(Repository repo, String revisionSpec, String rel)
            throws IOException {
        ObjectId commitId = repo.resolve(revisionSpec);
        if (commitId == null) {
            throw new IOException("Unknown revision: " + revisionSpec);
        }
        try (RevWalk rw = new RevWalk(repo)) {
            RevCommit commit = rw.parseCommit(commitId);
            try (TreeWalk tw = TreeWalk.forPath(repo, rel, commit.getTree())) {
                if (tw == null) {
                    throw new IOException("Path not in tree: " + rel);
                }
                ObjectId blobId = tw.getObjectId(0);
                return repo.open(blobId);
            }
        }
    }
}
