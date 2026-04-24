package com.bsg.docviz.util;

import com.bsg.docviz.dto.WorkAreaLineEditDto;
import org.junit.jupiter.api.Test;

import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

class WorkAreaLineMarkerQueueProcessorTest {

    @Test
    void twoEditsShiftSecondRange() {
        String original = "L01\nL02\nL03\nL04\nL05\n";
        WorkAreaLineEditDto e1 = new WorkAreaLineEditDto();
        e1.setStartLine(2);
        e1.setEndLine(2);
        e1.setReplacement("N2a\nN2b");
        WorkAreaLineEditDto e2 = new WorkAreaLineEditDto();
        e2.setStartLine(5);
        e2.setEndLine(5);
        e2.setReplacement("N5");
        String marked = WorkAreaLineMarkerQueueProcessor.buildMarkedDocument(original, List.of(e1, e2));
        assertTrue(marked.contains(">>> past >>>"));
        assertTrue(marked.contains(">>> current >>>"));
        assertTrue(marked.contains("L05") || marked.contains("N5"));
    }

    @Test
    void singleReplacement() {
        String original = "a\nb\nc\n";
        WorkAreaLineEditDto e = new WorkAreaLineEditDto();
        e.setStartLine(2);
        e.setEndLine(2);
        e.setReplacement("B");
        String marked = WorkAreaLineMarkerQueueProcessor.buildMarkedDocument(original, List.of(e));
        assertEquals(
                "a\n"
                        + ">>> past >>>\n"
                        + "b\n"
                        + ">>> current >>>\n"
                        + "B\n"
                        + "c\n",
                marked);
    }
}
