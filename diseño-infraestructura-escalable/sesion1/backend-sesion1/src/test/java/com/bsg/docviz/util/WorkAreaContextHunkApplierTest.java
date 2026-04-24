package com.bsg.docviz.util;

import com.bsg.docviz.dto.WorkAreaChangeBlockDto;
import org.junit.jupiter.api.Test;

import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

class WorkAreaContextHunkApplierTest {

    @Test
    void replaceKeepsContextAnchors() {
        String orig = "A\nB\nOLD\nC\nD\n";
        WorkAreaChangeBlockDto b = block(
                "r1",
                "replace",
                List.of("A", "B"),
                List.of("OLD"),
                List.of("NEW"),
                List.of("C", "D"));
        String out = WorkAreaContextHunkApplier.apply(orig, List.of(b));
        assertEquals("A\nB\nNEW\nC\nD\n", out);
    }

    @Test
    void insertBetweenContext() {
        String orig = "start\nANCHOR\nend\n";
        WorkAreaChangeBlockDto b = new WorkAreaChangeBlockDto();
        b.setId("i1");
        b.setType("insert");
        b.setContextBefore(List.of("start"));
        b.setOriginal(List.of());
        b.setReplacement(List.of("INSERT1", "INSERT2"));
        b.setContextAfter(List.of("ANCHOR"));
        String out = WorkAreaContextHunkApplier.apply(orig, List.of(b));
        assertEquals("start\nINSERT1\nINSERT2\nANCHOR\nend\n", out);
    }

    @Test
    void deleteRemovesOriginal() {
        String orig = "x\nDEL1\nDEL2\ny\n";
        WorkAreaChangeBlockDto b = block("d1", "delete", List.of("x"), List.of("DEL1", "DEL2"), List.of(), List.of("y"));
        String out = WorkAreaContextHunkApplier.apply(orig, List.of(b));
        assertEquals("x\ny\n", out);
    }

    @Test
    void ambiguousThrows() {
        String orig = "A\nX\nB\nX\nC\n";
        WorkAreaChangeBlockDto b = block("a1", "replace", List.of(), List.of("X"), List.of("Y"), List.of());
        assertThrows(IllegalArgumentException.class, () -> WorkAreaContextHunkApplier.apply(orig, List.of(b)));
    }

    /** Modelo sin indentación YAML; archivo real con 2 espacios — debe resolver con comparación tolerante. */
    @Test
    void replaceMatchesWhenOnlyLeadingWhitespaceDiffers() {
        String orig = "services:\n  findu-security:\n    image: x\n  redis:\n    image: y\n";
        WorkAreaChangeBlockDto b = block(
                "y1",
                "replace",
                List.of("services:"),
                List.of("findu-security:", "    image: x"),
                List.of("findu-security:", "    image: x-fixed"),
                List.of("redis:"));
        String out = WorkAreaContextHunkApplier.apply(orig, List.of(b));
        assertEquals(
                "services:\nfindu-security:\n    image: x-fixed\nredis:\n    image: y\n",
                out);
    }

    @Test
    void createFileIgnoresOriginal() {
        WorkAreaChangeBlockDto b = new WorkAreaChangeBlockDto();
        b.setType("create_file");
        b.setPath("a/b.txt");
        b.setContent(List.of("line1", "line2"));
        String out = WorkAreaContextHunkApplier.apply("ignored\n", List.of(b));
        assertEquals("line1\nline2\n", out);
    }

    private static WorkAreaChangeBlockDto block(
            String id,
            String type,
            List<String> cb,
            List<String> orig,
            List<String> repl,
            List<String> ca) {
        WorkAreaChangeBlockDto b = new WorkAreaChangeBlockDto();
        b.setId(id);
        b.setType(type);
        b.setContextBefore(cb);
        b.setOriginal(orig);
        b.setReplacement(repl);
        b.setContextAfter(ca);
        return b;
    }
}
