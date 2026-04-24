package com.bsg.docviz.util;

import org.eclipse.jgit.api.Git;
import org.eclipse.jgit.lib.Ref;
import org.eclipse.jgit.lib.Repository;

import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Collection;
import java.util.HashSet;
import java.util.Optional;
import java.util.Set;

/**
 * Resuelve la rama por defecto del remoto (HEAD simbólico vía {@code ls-remote}) o la rama actual en un clone local.
 */
public final class RemoteHeadBranchResolver {

    private RemoteHeadBranchResolver() {}

    /** HTTPS público o URL con credenciales incrustadas; falla silenciosamente si el remoto no es accesible. */
    public static Optional<String> forHttpsUrl(String url) {
        if (url == null || url.isBlank()) {
            return Optional.empty();
        }
        String u = url.trim();
        if (!u.toLowerCase().startsWith("https://")) {
            return Optional.empty();
        }
        try {
            Collection<Ref> refs = Git.lsRemoteRepository().setRemote(u).setHeads(true).call();
            for (Ref ref : refs) {
                if ("HEAD".equals(ref.getName()) && ref.isSymbolic()) {
                    return Optional.of(Repository.shortenRefName(ref.getTarget().getName()));
                }
            }
            Set<String> names = new HashSet<>();
            for (Ref ref : refs) {
                names.add(ref.getName());
            }
            if (names.contains("refs/heads/main")) {
                return Optional.of("main");
            }
            if (names.contains("refs/heads/master")) {
                return Optional.of("master");
            }
            return names.stream()
                    .filter(k -> k.startsWith("refs/heads/"))
                    .findFirst()
                    .map(Repository::shortenRefName);
        } catch (Exception ignored) {
            return Optional.empty();
        }
    }

    /** Directorio con {@code .git} válido. */
    public static Optional<String> forLocalPath(String localPath) {
        if (localPath == null || localPath.isBlank()) {
            return Optional.empty();
        }
        Path dir = Path.of(localPath.trim());
        try {
            if (!Files.isDirectory(dir)) {
                return Optional.empty();
            }
            try (Git git = Git.open(dir.toFile())) {
                String b = git.getRepository().getBranch();
                if (b != null && !b.isBlank()) {
                    return Optional.of(b);
                }
            }
        } catch (Exception ignored) {
        }
        return Optional.empty();
    }
}
