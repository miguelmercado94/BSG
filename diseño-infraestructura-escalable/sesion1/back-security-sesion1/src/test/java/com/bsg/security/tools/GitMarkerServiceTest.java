package com.bsg.security.tools;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

class GitMarkerServiceTest {

    @Test
    void sortsDescendingAndProducesVersionedFile(@TempDir Path dir) throws Exception {
        Path src = dir.resolve("Sample.java");
        List<String> original = List.of(
                "L1",
                "L2",
                "L3",
                "L4",
                "L5",
                "L6",
                "L7",
                "L8",
                "L9",
                "L10"
        );
        Files.write(src, original, StandardCharsets.UTF_8);

        List<FileChange> changes = List.of(
                new FileChange(2, 3, ChangeType.REPLACE, List.of("// rep")),
                new FileChange(8, 10, ChangeType.REMOVE, List.of())
        );

        GitMarkerService service = new GitMarkerService();
        Path out = service.applyGitMarkers(src, changes, 2);

        assertThat(out.getFileName().toString()).isEqualTo("Sample_V2.java");
        List<String> result = Files.readAllLines(out, StandardCharsets.UTF_8);

        // Primero se aplica el cambio con startLine mayor (8..10), luego el 2..3
        assertThat(result).containsExactly(
                "L1",
                "<<<<<<< CURRENT",
                "L2",
                "L3",
                "=======",
                "// rep",
                ">>>>>>> SUGGESTED",
                "L4",
                "L5",
                "L6",
                "L7",
                "<<<<<<< CURRENT",
                "L8",
                "L9",
                "L10",
                "=======",
                ">>>>>>> SUGGESTED"
        );
    }

    @Test
    void addInsertsBeforeLineWithoutRemoving(@TempDir Path dir) throws Exception {
        Path src = dir.resolve("a.txt");
        Files.write(src, List.of("a", "b", "c"), StandardCharsets.UTF_8);

        List<FileChange> changes = List.of(
                new FileChange(2, 2, ChangeType.ADD, List.of("NEW1", "NEW2"))
        );

        Path out = new GitMarkerService().applyGitMarkers(src, changes, 1);
        assertThat(Files.readAllLines(out, StandardCharsets.UTF_8)).containsExactly(
                "a",
                "<<<<<<< CURRENT",
                "=======",
                "NEW1",
                "NEW2",
                ">>>>>>> SUGGESTED",
                "b",
                "c"
        );
    }

    @Test
    void readChangesFromJsonArray(@TempDir Path dir) throws Exception {
        Path json = dir.resolve("c.json");
        Files.writeString(json, """
                [
                  { "startLine": 1, "endLine": 1, "type": "REPLACE", "content": ["x"] }
                ]
                """);

        List<FileChange> list = new GitMarkerService().readChangesFromJson(json);
        assertThat(list).hasSize(1);
        assertThat(list.get(0).type()).isEqualTo(ChangeType.REPLACE);
        assertThat(list.get(0).content()).containsExactly("x");
    }

    @Test
    void readChangesFromJsonObject(@TempDir Path dir) throws Exception {
        Path json = dir.resolve("c.json");
        Files.writeString(json, """
                { "changes": [ { "startLine": 2, "endLine": 2, "type": "ADD", "content": ["y"] } ] }
                """);

        List<FileChange> list = new GitMarkerService().readChangesFromJson(json);
        assertThat(list.get(0).type()).isEqualTo(ChangeType.ADD);
    }

    @Test
    void versionedSiblingPath_noExtension() {
        Path p = Path.of("C:/tmp/README");
        assertThat(GitMarkerService.versionedSiblingPath(p, 3).getFileName().toString()).isEqualTo("README_V3");
    }
}
