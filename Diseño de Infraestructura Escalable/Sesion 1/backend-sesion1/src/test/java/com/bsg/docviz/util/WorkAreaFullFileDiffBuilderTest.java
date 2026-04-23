package com.bsg.docviz.util;

import com.bsg.docviz.dto.WorkAreaDiffLineDto;
import org.junit.jupiter.api.Test;

import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

class WorkAreaFullFileDiffBuilderTest {

    @Test
    void fullDiffIncludesAllUnchangedLines() {
        String orig = "a\nb\nc\nd\n";
        String rev = "a\nx\nc\nd\n";
        List<WorkAreaDiffLineDto> lines = WorkAreaFullFileDiffBuilder.buildFullDiffLines(orig, rev);
        assertEquals(5, lines.size());
        assertEquals("context", lines.get(0).getKind());
        assertEquals("a", lines.get(0).getText());
        assertEquals("removed", lines.get(1).getKind());
        assertEquals("b", lines.get(1).getText());
        assertEquals("added", lines.get(2).getKind());
        assertEquals("x", lines.get(2).getText());
        assertEquals("context", lines.get(3).getKind());
        assertEquals("c", lines.get(3).getText());
        assertEquals("context", lines.get(4).getKind());
        assertEquals("d", lines.get(4).getText());
    }

    @Test
    void partialApplyThenFullDiffRoundTrip() {
        String original = "<p>\n  <v>1</v>\n  <v>2</v>\n</p>\n";
        var dl = List.of(
                line("context", "<p>"),
                line("context", "  <v>1</v>"),
                line("removed", "  <v>2</v>"),
                line("added", "  <v>3</v>"),
                line("context", "</p>")
        );
        String revised = WorkAreaPartialDiffApplier.apply(original, dl);
        List<WorkAreaDiffLineDto> full = WorkAreaFullFileDiffBuilder.buildFullDiffLines(original, revised);
        assertTrue(full.size() >= 5);
        long removed = full.stream().filter(l -> "removed".equals(l.getKind())).count();
        long added = full.stream().filter(l -> "added".equals(l.getKind())).count();
        assertEquals(1, removed);
        assertEquals(1, added);
    }

    private static com.bsg.docviz.dto.WorkAreaDiffLineDto line(String k, String t) {
        var d = new com.bsg.docviz.dto.WorkAreaDiffLineDto();
        d.setKind(k);
        d.setText(t);
        return d;
    }
}
