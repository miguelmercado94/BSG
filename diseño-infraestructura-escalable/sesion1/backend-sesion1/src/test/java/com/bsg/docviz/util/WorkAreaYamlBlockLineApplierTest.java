package com.bsg.docviz.util;

import com.bsg.docviz.dto.WorkAreaYamlProposalBlockDto;
import org.junit.jupiter.api.Test;

import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;

class WorkAreaYamlBlockLineApplierTest {

    @Test
    void replaceMiddle() {
        String orig = "a\nb\nc\nd\ne\n";
        WorkAreaYamlProposalBlockDto b = new WorkAreaYamlProposalBlockDto();
        b.setStart(2);
        b.setEnd(3);
        b.setType("REPLACE");
        b.setLines(List.of("B", "C"));
        String out = WorkAreaYamlBlockLineApplier.apply(orig, List.of(b));
        assertEquals("a\nB\nC\nd\ne\n", out);
    }

    @Test
    void deleteThenReplaceOrder() {
        String orig = "1\n2\n3\n4\n5\n";
        WorkAreaYamlProposalBlockDto del = new WorkAreaYamlProposalBlockDto();
        del.setStart(4);
        del.setEnd(5);
        del.setType("DELETE");
        del.setLines(List.of());
        WorkAreaYamlProposalBlockDto rep = new WorkAreaYamlProposalBlockDto();
        rep.setStart(2);
        rep.setEnd(2);
        rep.setType("REPLACE");
        rep.setLines(List.of("two"));
        String out = WorkAreaYamlBlockLineApplier.apply(orig, List.of(del, rep));
        assertEquals("1\ntwo\n3\n", out);
    }

    @Test
    void newOnBlankLine() {
        String orig = "head\n\nfoot\n";
        WorkAreaYamlProposalBlockDto n = new WorkAreaYamlProposalBlockDto();
        n.setStart(2);
        n.setEnd(2);
        n.setType("NEW");
        n.setLines(List.of("mid"));
        String out = WorkAreaYamlBlockLineApplier.apply(orig, List.of(n));
        assertEquals("head\nmid\nfoot\n", out);
    }
}
