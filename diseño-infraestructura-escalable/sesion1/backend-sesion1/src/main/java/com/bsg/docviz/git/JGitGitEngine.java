package com.bsg.docviz.git;

import org.eclipse.jgit.api.Git;
import org.eclipse.jgit.api.errors.GitAPIException;
import org.eclipse.jgit.lib.FileMode;
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
import java.util.LinkedHashSet;
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
                    // Sin esto, los servicios en submódulos (p. ej. autenticacionservice/) no aparecen en el tree → 0 .java indexables.
                    .setCloneSubmodules(true)
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
                        String p = treeWalk.getPathString();
                        if (FileMode.GITLINK.equals(treeWalk.getFileMode(0))) {
                            Path subRoot = repoRoot.resolve(p);
                            if (isNestedGitWorkTree(subRoot)) {
                                try {
                                    String subRev = resolveListingRevision(subRoot);
                                    for (String inner : listTrackedFilePaths(subRoot, subRev)) {
                                        paths.add(p + "/" + inner);
                                    }
                                } catch (IOException ex) {
                                    // Submódulo sin checkout o sin HEAD: no bloquear listado del padre
                                    paths.add(p);
                                }
                            } else {
                                paths.add(p);
                            }
                        } else {
                            paths.add(p);
                        }
                    }
                }
            }
            return expandTopLevelSubmoduleFolders(repoRoot, paths);
        }
    }

    /**
     * Si el árbol del padre solo incluye el nombre del submódulo (gitlink) o TreeWalk no descendió, expande
     * carpetas de primer nivel que sean repositorios Git anidados.
     */
    private List<String> expandTopLevelSubmoduleFolders(Path repoRoot, List<String> paths) throws IOException {
        LinkedHashSet<String> merged = new LinkedHashSet<>(paths);
        for (String p : paths) {
            if (p == null || p.isBlank() || p.contains("/")) {
                continue;
            }
            Path sub = repoRoot.resolve(p);
            if (!isNestedGitWorkTree(sub)) {
                continue;
            }
            boolean hasNestedListed = paths.stream().anyMatch(x -> !x.equals(p) && x.startsWith(p + "/"));
            if (hasNestedListed) {
                merged.remove(p);
                continue;
            }
            try {
                String subRev = resolveListingRevision(sub);
                List<String> inner = listTrackedFilePaths(sub, subRev);
                if (!inner.isEmpty()) {
                    merged.remove(p);
                    for (String in : inner) {
                        merged.add(p + "/" + in);
                    }
                }
            } catch (IOException ignored) {
                // mantener entrada p
            }
        }
        return new ArrayList<>(merged);
    }

    private static boolean isNestedGitWorkTree(Path dir) {
        if (dir == null || !Files.isDirectory(dir)) {
            return false;
        }
        Path dotGit = dir.resolve(".git");
        return Files.exists(dotGit);
    }

    /**
     * Raíz del repo donde vive el blob, revisión efectiva y ruta relativa dentro de ese repo
     * (tras cruzar prefijos de submódulo).
     */
    private record ResolvedBlob(Path root, String revision, String pathInRepo) {}

    private static String normalizeEnginePath(String repoRelativePath) {
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

    private static ObjectLoader tryBlobAt(Repository repo, RevCommit commit, String rel) throws IOException {
        try (TreeWalk tw = TreeWalk.forPath(repo, rel, commit.getTree())) {
            if (tw == null) {
                return null;
            }
            FileMode mode = tw.getFileMode(0);
            if (FileMode.GITLINK.equals(mode) || FileMode.TREE.equals(mode)) {
                return null;
            }
            return repo.open(tw.getObjectId(0));
        }
    }

    private static ObjectId submoduleCommitAt(Repository parent, RevCommit parentCommit, String submodulePath)
            throws IOException {
        try (TreeWalk tw = TreeWalk.forPath(parent, submodulePath, parentCommit.getTree())) {
            if (tw == null || !FileMode.GITLINK.equals(tw.getFileMode(0))) {
                return null;
            }
            return tw.getObjectId(0);
        }
    }

    /**
     * Rutas listadas como {@code submódulo/ruta} viven en el árbol del sub-repositorio, no en el commit del padre.
     */
    private ResolvedBlob resolveForBlobOps(Path repoRoot, String revisionSpec, String repoRelativePath)
            throws IOException {
        String path = normalizeEnginePath(repoRelativePath);
        try (Git git = Git.open(repoRoot.toFile())) {
            Repository repository = git.getRepository();
            ObjectId commitId = repository.resolve(revisionSpec);
            if (commitId == null) {
                throw new IOException("Unknown revision: " + revisionSpec);
            }
            try (RevWalk rw = new RevWalk(repository)) {
                RevCommit commit = rw.parseCommit(commitId);
                if (tryBlobAt(repository, commit, path) != null) {
                    return new ResolvedBlob(repoRoot, revisionSpec, path);
                }
                for (int slash = path.indexOf('/'); slash > 0; slash = path.indexOf('/', slash + 1)) {
                    String prefix = path.substring(0, slash);
                    String suffix = path.substring(slash + 1);
                    if (suffix.isEmpty()) {
                        continue;
                    }
                    Path nestedRoot = repoRoot.resolve(prefix);
                    if (!isNestedGitWorkTree(nestedRoot)) {
                        continue;
                    }
                    ObjectId gitlink = submoduleCommitAt(repository, commit, prefix);
                    String innerRev = gitlink != null ? gitlink.name() : resolveListingRevision(nestedRoot);
                    return resolveForBlobOps(nestedRoot, innerRev, suffix);
                }
            }
        }
        throw new IOException("Path not in tree: " + path);
    }

    @Override
    public long blobSizeBytes(Path repoRoot, String revisionSpec, String repoRelativePath) throws IOException {
        ResolvedBlob r = resolveForBlobOps(repoRoot, revisionSpec, repoRelativePath);
        try (Git git = Git.open(r.root().toFile())) {
            return openBlobLoader(git.getRepository(), r.revision(), r.pathInRepo()).getSize();
        }
    }

    @Override
    public void checkoutPath(Path repoRoot, String revisionSpec, String repoRelativePath) throws IOException {
        ResolvedBlob r = resolveForBlobOps(repoRoot, revisionSpec, repoRelativePath);
        try (Git git = Git.open(r.root().toFile())) {
            git.checkout().setStartPoint(r.revision()).addPath(r.pathInRepo()).call();
        } catch (GitAPIException e) {
            throw new IOException("git checkout failed: " + e.getMessage(), e);
        }
    }

    @Override
    public byte[] readBlob(Path repoRoot, String revisionSpec, String repoRelativePath) throws IOException {
        ResolvedBlob r = resolveForBlobOps(repoRoot, revisionSpec, repoRelativePath);
        try (Git git = Git.open(r.root().toFile())) {
            return openBlobLoader(git.getRepository(), r.revision(), r.pathInRepo()).getBytes();
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
