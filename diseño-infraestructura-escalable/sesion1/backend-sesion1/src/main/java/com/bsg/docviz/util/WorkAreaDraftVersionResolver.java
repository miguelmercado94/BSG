package com.bsg.docviz.util;

import java.io.IOException;
import java.io.UncheckedIOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Locale;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Stream;

/**
 * Calcula el siguiente sufijo {@code _vN} para borradores en el mismo directorio que el archivo fuente.
 */
public final class WorkAreaDraftVersionResolver {

    private static final Pattern DRAFT_SUFFIX = Pattern.compile("(?i)^(.+)_v(\\d+)(\\..+)\\.txt$");

    private WorkAreaDraftVersionResolver() {}

    /**
     * Próximo número de versión (1 si no hay borradores previos).
     */
    public static int nextVersion(Path repoRoot, String sourceRelativePath) {
        String rel = WorkAreaDraftPathBuilder.normalizeSourceRelativePath(sourceRelativePath);
        int slash = rel.lastIndexOf('/');
        String dir = slash >= 0 ? rel.substring(0, slash) : "";
        String file = slash >= 0 ? rel.substring(slash + 1) : rel;
        file = WorkAreaDraftPathBuilder.sanitizeFileNameLikeOriginalInRepo(file);
        int dot = file.lastIndexOf('.');
        String base = dot > 0 ? file.substring(0, dot) : file;
        String extWithDot = dot > 0 ? file.substring(dot) : "";
        Path dirAbs = dir.isEmpty() ? repoRoot : repoRoot.resolve(dir).normalize();
        if (!dirAbs.startsWith(repoRoot.normalize())) {
            return 1;
        }
        int max = 0;
        if (!Files.isDirectory(dirAbs)) {
            return 1;
        }
        try (Stream<Path> stream = Files.list(dirAbs)) {
            for (Path p : stream.toList()) {
                if (!Files.isRegularFile(p)) {
                    continue;
                }
                String name = p.getFileName().toString();
                Matcher m = DRAFT_SUFFIX.matcher(name);
                if (m.matches()) {
                    String b = m.group(1);
                    String ext = m.group(3);
                    if (b.equalsIgnoreCase(base) && extWithDot.equalsIgnoreCase(ext)) {
                        max = Math.max(max, Integer.parseInt(m.group(2)));
                    }
                }
            }
        } catch (IOException e) {
            throw new UncheckedIOException(e);
        }
        return max + 1;
    }
}
