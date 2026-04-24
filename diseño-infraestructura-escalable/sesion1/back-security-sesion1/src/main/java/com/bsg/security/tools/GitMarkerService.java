package com.bsg.security.tools;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;

/**
 * Inyecta marcadores de conflicto estilo Git (CURRENT / SUGGESTED) sin modificar el archivo original.
 * Los cambios se aplican de abajo hacia arriba (por {@code startLine} descendente) para que los índices
 * del JSON (referidos al archivo original) sigan siendo válidos.
 */
public final class GitMarkerService {

    private static final String MARKER_CURRENT = "<<<<<<< CURRENT";
    private static final String MARKER_DIVIDER = "=======";
    private static final String MARKER_SUGGESTED = ">>>>>>> SUGGESTED";

    private final ObjectMapper objectMapper;

    public GitMarkerService() {
        this(new ObjectMapper());
    }

    public GitMarkerService(ObjectMapper objectMapper) {
        this.objectMapper = objectMapper;
    }

    /**
     * Lee cambios desde JSON: raíz {@code [ ... ]} o {@code { "changes": [ ... ] }}.
     */
    public List<FileChange> readChangesFromJson(Path jsonPath) throws IOException {
        String json = Files.readString(jsonPath, StandardCharsets.UTF_8);
        String trimmed = json.stripLeading();
        if (trimmed.startsWith("[")) {
            return objectMapper.readValue(json, new TypeReference<>() {});
        }
        ChangesPayload payload = objectMapper.readValue(json, ChangesPayload.class);
        return payload.changes();
    }

    /**
     * Aplica marcadores y escribe {@code [base]_V[version][ext]} junto al archivo original.
     *
     * @param filePath ruta del archivo fuente (1-based line numbers en {@code changes})
     * @param changes  lista de cambios (se ordena internamente por {@code startLine} descendente)
     * @param version  número de versión en el nombre de salida
     * @return ruta del archivo generado
     */
    public Path applyGitMarkers(Path filePath, List<FileChange> changes, int version) throws IOException {
        List<String> lines = new ArrayList<>(Files.readAllLines(filePath, StandardCharsets.UTF_8));

        List<FileChange> sorted = new ArrayList<>(changes);
        sorted.sort(Comparator.comparingInt(FileChange::startLine).reversed());

        for (FileChange change : sorted) {
            applySingleChange(lines, change);
        }

        Path newPath = versionedSiblingPath(filePath, version);
        Files.write(newPath, lines, StandardCharsets.UTF_8);
        return newPath;
    }

    public Path applyGitMarkersFromJson(Path filePath, Path jsonPath, int version) throws IOException {
        return applyGitMarkers(filePath, readChangesFromJson(jsonPath), version);
    }

    static Path versionedSiblingPath(Path filePath, int version) {
        Path parent = filePath.getParent();
        String fileName = filePath.getFileName().toString();
        int dot = fileName.lastIndexOf('.');
        String base;
        String ext;
        if (dot <= 0 || dot == fileName.length() - 1) {
            base = fileName;
            ext = "";
        } else {
            base = fileName.substring(0, dot);
            ext = fileName.substring(dot);
        }
        String outName = base + "_V" + version + ext;
        return parent == null ? Paths.get(outName) : parent.resolve(outName);
    }

    private void applySingleChange(List<String> lines, FileChange change) {
        ChangeType type = change.type();
        int start1 = change.startLine();
        int end1 = change.endLine();

        if (start1 < 1) {
            throw new IllegalArgumentException("startLine debe ser >= 1, recibido: " + start1);
        }

        switch (type) {
            case ADD -> applyAdd(lines, change, start1);
            case REMOVE -> applyRemoveOrReplace(lines, change, start1, end1, true);
            case REPLACE -> applyRemoveOrReplace(lines, change, start1, end1, false);
        }
    }

    /**
     * ADD: inserta antes de la línea {@code startLine} (1-based). No elimina líneas del original.
     */
    private void applyAdd(List<String> lines, FileChange change, int start1) {
        int insertAt = Math.min(start1 - 1, lines.size());
        List<String> originalBlock = List.of();
        List<String> suggested = change.content();
        List<String> marked = buildMarkedBlock(originalBlock, suggested);
        lines.addAll(insertAt, marked);
    }

    /**
     * REMOVE / REPLACE: rango inclusivo [startLine, endLine] en numeración 1-based del archivo original.
     */
    private void applyRemoveOrReplace(List<String> lines, FileChange change, int start1, int end1, boolean removeOnly) {
        if (end1 < start1) {
            throw new IllegalArgumentException("endLine debe ser >= startLine para " + change.type()
                    + ", recibido: " + start1 + ".." + end1);
        }
        int startIdx = start1 - 1;
        int endExclusive = end1; // línea end1 tiene índice end1-1; fin exclusivo del subList = end1
        if (startIdx > lines.size()) {
            throw new IllegalArgumentException("startLine fuera de rango: " + start1 + " (líneas: " + lines.size() + ")");
        }
        endExclusive = Math.min(endExclusive, lines.size());
        if (startIdx > endExclusive) {
            throw new IllegalArgumentException("Rango inválido tras ajuste: " + start1 + ".." + end1);
        }

        List<String> originalBlock = new ArrayList<>(lines.subList(startIdx, endExclusive));
        List<String> suggested = removeOnly ? List.of() : change.content();

        List<String> marked = buildMarkedBlock(originalBlock, suggested);
        lines.subList(startIdx, endExclusive).clear();
        lines.addAll(startIdx, marked);
    }

    private static List<String> buildMarkedBlock(List<String> originalBlock, List<String> suggested) {
        List<String> marked = new ArrayList<>();
        marked.add(MARKER_CURRENT);
        marked.addAll(originalBlock);
        marked.add(MARKER_DIVIDER);
        marked.addAll(suggested);
        marked.add(MARKER_SUGGESTED);
        return marked;
    }

    public static void main(String[] args) throws IOException {
        if (args.length < 3) {
            System.err.println("Uso: GitMarkerService <archivo> <cambios.json> <version>");
            System.err.println("  JSON: [ { \"startLine\", \"endLine\", \"type\", \"content\" } ] o { \"changes\": [ ... ] }");
            System.exit(1);
        }
        Path file = Paths.get(args[0]);
        Path json = Paths.get(args[1]);
        int version = Integer.parseInt(args[2]);
        GitMarkerService service = new GitMarkerService();
        Path out = service.applyGitMarkersFromJson(file, json, version);
        System.out.println("Archivo generado: " + out.toAbsolutePath());
    }
}
