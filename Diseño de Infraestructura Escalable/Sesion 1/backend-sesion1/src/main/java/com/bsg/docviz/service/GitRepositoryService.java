package com.bsg.docviz.service;

import com.bsg.docviz.config.DocvizProperties;
import com.bsg.docviz.dto.GitConnectRequest;
import com.bsg.docviz.dto.TreeNodeDto;
import com.bsg.docviz.security.CurrentUser;
import com.bsg.docviz.util.FileTreeBuilder;
import org.springframework.stereotype.Service;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.nio.file.FileVisitResult;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.SimpleFileVisitor;
import java.nio.file.attribute.BasicFileAttributes;
import java.time.Duration;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.concurrent.TimeUnit;

@Service
public class GitRepositoryService {

    private static final Duration CLONE_TIMEOUT = Duration.ofMinutes(15);
    private static final Duration GIT_OP_TIMEOUT = Duration.ofMinutes(2);

    private final SessionRegistry sessionRegistry;
    private final DocvizProperties docvizProperties;

    public GitRepositoryService(SessionRegistry sessionRegistry, DocvizProperties docvizProperties) {
        this.sessionRegistry = sessionRegistry;
        this.docvizProperties = docvizProperties;
    }

    public String resolveRevisionForListing(Path repoRoot) {
        try {
            return resolveRevisionForListingInternal(repoRoot);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new IllegalStateException("Git operation interrupted", e);
        } catch (IOException e) {
            throw new IllegalStateException("Git I/O error: " + e.getMessage(), e);
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
            throw new IllegalStateException("Git I/O error: " + e.getMessage(), e);
        }
    }

    public long objectSizeBytes(Path repoRoot, String revisionSpec, String repoRelativePath) {
        try {
            String spec = revisionSpec + ":" + repoRelativePath;
            String out = runGit(repoRoot, GIT_OP_TIMEOUT, "git", "cat-file", "-s", spec).stdoutText().trim();
            return Long.parseLong(out);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new IllegalStateException("Git operation interrupted", e);
        } catch (IOException e) {
            throw new IllegalStateException("Git I/O error: " + e.getMessage(), e);
        }
    }

    public byte[] readBlob(Path repoRoot, String revisionSpec, String repoRelativePath) {
        try {
            String spec = revisionSpec + ":" + repoRelativePath;
            return runGit(repoRoot, GIT_OP_TIMEOUT, "git", "show", spec).stdoutBytes();
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new IllegalStateException("Git operation interrupted", e);
        } catch (IOException e) {
            throw new IllegalStateException("Git I/O error: " + e.getMessage(), e);
        }
    }

    public void connect(GitConnectRequest req) {
        try {
            connectInternal(req);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new IllegalStateException("Git operation interrupted", e);
        } catch (IOException e) {
            throw new IllegalStateException("Git I/O error: " + e.getMessage(), e);
        }
    }

    private void connectInternal(GitConnectRequest req) throws IOException, InterruptedException {
        UserRepositoryState st = sessionRegistry.current();

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

        st.getContentCache().clear();
        String rootFolderLabel = computeRootFolderLabel(req);
        st.setConnected(root, managedCloneRoot, rev, tree, rootFolderLabel);
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

    private Path cloneMetadataOnly(String cloneUrl, String folderName) throws IOException, InterruptedException {
        Path masters = docvizProperties.resolveRootDirectory();
        Path userDir = masters.resolve(CurrentUser.require());
        Files.createDirectories(userDir);

        Path targetDir = userDir.resolve(folderName);
        if (Files.exists(targetDir)) {
            deleteRecursively(targetDir);
        }

        List<String> cmd = new ArrayList<>();
        cmd.add("git");
        cmd.add("clone");
        cmd.add("--filter=blob:none");
        cmd.add("--no-checkout");
        cmd.add(cloneUrl);
        cmd.add(folderName);

        GitResult r = runGit(userDir, CLONE_TIMEOUT, cmd.toArray(String[]::new));
        if (r.exitCode() != 0) {
            if (Files.exists(targetDir)) {
                deleteRecursivelyQuietly(targetDir);
            }
            String err = r.stderrText().trim();
            String out = r.stdoutText().trim();
            String msg = "git clone failed: " + err + (out.isBlank() ? "" : " | " + out);
            throw new IllegalStateException(msg);
        }
        return targetDir;
    }

    static String slugFromGitUrl(String repositoryUrl) {
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
            deleteRecursively(root);
        } catch (IOException e) {
            throw new IllegalStateException("Could not delete clone directory: " + e.getMessage(), e);
        }
    }

    private void verifyGitRepo(Path dir) throws IOException, InterruptedException {
        GitResult r = runGit(dir, GIT_OP_TIMEOUT, "git", "rev-parse", "--is-inside-work-tree");
        if (r.exitCode() != 0 || !r.stdoutText().trim().equalsIgnoreCase("true")) {
            throw new IllegalArgumentException("localPath is not a git working tree");
        }
    }

    private String resolveRevisionForListingInternal(Path repoRoot) throws IOException, InterruptedException {
        GitResult h = runGit(repoRoot, GIT_OP_TIMEOUT, "git", "rev-parse", "--verify", "HEAD");
        if (h.exitCode() == 0 && !h.stdoutText().trim().isBlank()) {
            return "HEAD";
        }
        String[] candidates = {"origin/main", "origin/master", "main", "master"};
        for (String c : candidates) {
            GitResult r = runGit(repoRoot, GIT_OP_TIMEOUT, "git", "rev-parse", "--verify", c);
            if (r.exitCode() == 0 && !r.stdoutText().trim().isBlank()) {
                return c;
            }
        }
        throw new IllegalStateException("Could not resolve HEAD, origin/main or origin/master to list the tree");
    }

    public List<String> listTrackedFiles(Path repoRoot, String revisionSpec) throws IOException, InterruptedException {
        GitResult r = runGit(repoRoot, GIT_OP_TIMEOUT, "git", "ls-tree", "-r", "--name-only", revisionSpec);
        if (r.exitCode() != 0) {
            throw new IllegalStateException("git ls-tree failed: " + r.stderrText());
        }
        List<String> lines = new ArrayList<>();
        for (String line : r.stdoutText().split("\r?\n")) {
            if (!line.isBlank()) {
                lines.add(line);
            }
        }
        return lines;
    }

    private static GitResult runGit(Path workingDir, Duration timeout, String... command) throws IOException, InterruptedException {
        ProcessBuilder pb = new ProcessBuilder(command);
        if (workingDir != null) {
            pb.directory(workingDir.toFile());
        }
        pb.environment().put("GIT_TERMINAL_PROMPT", "0");
        pb.redirectErrorStream(false);
        Process p = pb.start();
        byte[] out = readAllBytes(p.getInputStream());
        byte[] err = readAllBytes(p.getErrorStream());
        boolean finished = p.waitFor(timeout.toMillis(), TimeUnit.MILLISECONDS);
        if (!finished) {
            p.destroyForcibly();
            throw new IllegalStateException("git command timed out: " + String.join(" ", command));
        }
        return new GitResult(p.exitValue(), out, err);
    }

    private static byte[] readAllBytes(InputStream in) throws IOException {
        try (InputStream input = in; ByteArrayOutputStream bos = new ByteArrayOutputStream()) {
            input.transferTo(bos);
            return bos.toByteArray();
        }
    }

    private static void deleteRecursively(Path root) throws IOException {
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

    private record GitResult(int exitCode, byte[] stdout, byte[] stderr) {
        String stdoutText() {
            return new String(stdout, StandardCharsets.UTF_8);
        }

        String stderrText() {
            return new String(stderr, StandardCharsets.UTF_8);
        }

        byte[] stdoutBytes() {
            return stdout;
        }
    }
}
