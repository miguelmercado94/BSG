package com.bsg.docviz.util;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

class WorkAreaProposalContentHeuristicsTest {

    @Test
    void detectsStubListAsInvalid() {
        String orig = "x\n".repeat(80);
        String stub =
                "---\n"
                        + "services:\n"
                        + "- postgres\n"
                        + "- localstack\n"
                        + "- findu-security\n";
        assertTrue(WorkAreaProposalContentHeuristics.looksLikeInvalidYamlStub(stub, orig));
        assertFalse(WorkAreaProposalContentHeuristics.shouldPreferFullFileContent(stub, orig));
    }

    @Test
    void acceptsFullComposeLikeContent() {
        String orig = "x\n".repeat(80);
        String full =
                "services:\n"
                        + "  a:\n"
                        + "    image: t\n"
                        + "  b:\n"
                        + "    image: u\n"
                        + "  c:\n"
                        + "    image: v\n"
                        + "  d:\n"
                        + "    image: w\n"
                        + "  e:\n"
                        + "    image: z\n"
                        + "  f:\n"
                        + "    image: y\n"
                        + "  g:\n"
                        + "    image: q\n"
                        + "  h:\n"
                        + "    image: r\n"
                        + "  i:\n"
                        + "    image: s\n"
                        + "  j:\n"
                        + "    image: p\n"
                        + "  k:\n"
                        + "    image: o\n"
                        + "  l:\n"
                        + "    image: n\n";
        assertFalse(WorkAreaProposalContentHeuristics.looksLikeInvalidYamlStub(full, orig));
        assertTrue(WorkAreaProposalContentHeuristics.shouldPreferFullFileContent(full, orig));
    }

    @Test
    void sanitizerRemovesMarkerLines() {
        String in = "a\n<<<<<<< DocViz (original)\nb\n=======\nc\n>>>>>>> DocViz (propuesto)\nd";
        String out = WorkAreaRepoFileSanitizer.stripDocvizMergeMarkerLines(in);
        assertFalse(out.contains("<<<<<<<"));
        assertTrue(out.contains("a") && out.contains("b") && out.contains("c") && out.contains("d"));
    }
}
