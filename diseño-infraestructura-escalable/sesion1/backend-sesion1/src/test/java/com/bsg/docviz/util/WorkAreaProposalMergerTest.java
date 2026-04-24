package com.bsg.docviz.util;

import com.bsg.docviz.dto.WorkAreaLineEditDto;
import com.bsg.docviz.dto.WorkAreaProposalItemDto;
import org.junit.jupiter.api.Test;

import java.util.ArrayList;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;

class WorkAreaProposalMergerTest {

    @Test
    void sameSourcePathMergesLineEditsSorted() {
        WorkAreaProposalItemDto a = new WorkAreaProposalItemDto();
        a.setId("a");
        a.setSourcePath("findu/docker-compose.yml");
        WorkAreaLineEditDto e2 = new WorkAreaLineEditDto();
        e2.setStartLine(10);
        e2.setEndLine(10);
        e2.setReplacement("x");
        a.setLineEdits(new ArrayList<>(List.of(e2)));

        WorkAreaProposalItemDto b = new WorkAreaProposalItemDto();
        b.setId("b");
        b.setSourcePath("docker-compose.yml");
        WorkAreaLineEditDto e1 = new WorkAreaLineEditDto();
        e1.setStartLine(2);
        e1.setEndLine(3);
        e1.setReplacement("y");
        b.setLineEdits(new ArrayList<>(List.of(e1)));

        List<WorkAreaProposalItemDto> in = new ArrayList<>(List.of(a, b));
        List<WorkAreaProposalItemDto> out = WorkAreaProposalMerger.collapseBySourcePath(in, "findu");
        assertEquals(1, out.size());
        assertEquals("a", out.get(0).getId());
        List<WorkAreaLineEditDto> edits = out.get(0).getLineEdits();
        assertEquals(2, edits.size());
        assertEquals(2, edits.get(0).getStartLine());
        assertEquals(10, edits.get(1).getStartLine());
    }

    @Test
    void mergeKeyStripsUiPrefix() {
        WorkAreaProposalItemDto p = new WorkAreaProposalItemDto();
        p.setId("x");
        p.setSourcePath("findu/pom.xml");
        assertEquals("pom.xml", WorkAreaProposalMerger.mergeKey(p, "findu"));
    }
}
