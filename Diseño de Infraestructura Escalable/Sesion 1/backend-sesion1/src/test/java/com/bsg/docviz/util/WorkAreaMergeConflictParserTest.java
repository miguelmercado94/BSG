package com.bsg.docviz.util;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;

class WorkAreaMergeConflictParserTest {

    @Test
    void newFormatRoundTrip() {
        String merged = WorkAreaMergeConflictFormatter.format("a\nb", "c\nd");
        assertEquals("c\nd", WorkAreaMergeConflictParser.extractRevised(merged));
        assertEquals("a\nb", WorkAreaMergeConflictParser.extractOriginal(merged));
    }

    @Test
    void legacyFormatStillParsed() {
        String legacy =
                "<<<<<<< DocViz (original)\n"
                        + "x\n"
                        + "=======\n"
                        + "y\n"
                        + ">>>>>>> DocViz (propuesto)\n";
        assertEquals("y", WorkAreaMergeConflictParser.extractRevised(legacy));
        assertEquals("x", WorkAreaMergeConflictParser.extractOriginal(legacy));
    }
}
