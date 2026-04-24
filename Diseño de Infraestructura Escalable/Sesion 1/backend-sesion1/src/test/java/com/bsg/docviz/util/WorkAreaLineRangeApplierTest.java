package com.bsg.docviz.util;

import com.bsg.docviz.dto.WorkAreaLineEditDto;
import org.junit.jupiter.api.Test;

import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

class WorkAreaLineRangeApplierTest {

    @Test
    void replacesSingleRange() {
        String orig = "a\nb\nc\nd\n";
        WorkAreaLineEditDto e = new WorkAreaLineEditDto();
        e.setStartLine(2);
        e.setEndLine(3);
        e.setReplacement("X\nY");
        String out = WorkAreaLineRangeApplier.apply(orig, List.of(e));
        assertEquals("a\nX\nY\nd\n", out);
    }

    @Test
    void deletesRangeWithEmptyReplacement() {
        String orig = "a\nb\nc\n";
        WorkAreaLineEditDto e = new WorkAreaLineEditDto();
        e.setStartLine(2);
        e.setEndLine(2);
        e.setReplacement("");
        String out = WorkAreaLineRangeApplier.apply(orig, List.of(e));
        assertEquals("a\nc\n", out);
    }

    @Test
    void twoNonOverlappingEdits() {
        String orig = "a\nb\nc\nd\n";
        WorkAreaLineEditDto e1 = new WorkAreaLineEditDto();
        e1.setStartLine(1);
        e1.setEndLine(1);
        e1.setReplacement("A");
        WorkAreaLineEditDto e2 = new WorkAreaLineEditDto();
        e2.setStartLine(4);
        e2.setEndLine(4);
        e2.setReplacement("D");
        String out = WorkAreaLineRangeApplier.apply(orig, List.of(e1, e2));
        assertEquals("A\nb\nc\nD\n", out);
    }

    @Test
    void overlapThrows() {
        String orig = "a\nb\nc\n";
        WorkAreaLineEditDto e1 = new WorkAreaLineEditDto();
        e1.setStartLine(1);
        e1.setEndLine(2);
        WorkAreaLineEditDto e2 = new WorkAreaLineEditDto();
        e2.setStartLine(2);
        e2.setEndLine(3);
        assertThrows(IllegalArgumentException.class, () -> WorkAreaLineRangeApplier.apply(orig, List.of(e1, e2)));
    }
}
