package com.bsg.docviz.util;

import com.bsg.docviz.dto.WorkAreaProposalItemDto;
import org.junit.jupiter.api.Test;

import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

class WorkAreaProposalYamlParserTest {

    @Test
    void parsesFencedYaml() {
        String answer =
                "Aquí va el análisis.\n```yaml\n"
                        + "proposals:\n"
                        + "- path: REPO/micro/pom.xml\n"
                        + "  new: false\n"
                        + "  blocks:\n"
                        + "  - start: 1\n"
                        + "    end: 1\n"
                        + "    type: REPLACE\n"
                        + "    lines:\n"
                        + "    - \"<project>\"\n"
                        + "```\n";
        List<WorkAreaProposalItemDto> items = WorkAreaProposalYamlParser.parseProposalsFromAnswer(answer);
        assertEquals(1, items.size());
        WorkAreaProposalItemDto p = items.get(0);
        assertEquals("micro/pom.xml", p.getSourcePath());
        assertEquals("REPLACE", p.getYamlBlocks().get(0).getType());
        assertEquals(1, p.getYamlBlocks().get(0).getStart());
        assertEquals("<project>", p.getYamlBlocks().get(0).getLines().get(0));
    }

    @Test
    void stripYamlFences() {
        String s =
                "intro\n```yaml\nproposals:\n- path: REPO/a/b.txt\n  new: false\n  blocks:\n"
                        + "  - { start: 1, end: 1, type: REPLACE, lines: [x] }\n```\noutro";
        String st = WorkAreaProposalYamlParser.stripFencedYamlBlocks(s);
        assertFalse(st.contains("```"));
        assertTrue(st.contains("intro"));
        assertTrue(st.contains("outro"));
        assertFalse(st.contains("proposals:"));
    }

    @Test
    void pathCodecLocal() {
        WorkAreaProposalPathCodec.Parsed p =
                WorkAreaProposalPathCodec.parse("LOCAL/my-bucket/folder/file.yml");
        assertEquals(WorkAreaProposalPathCodec.Kind.LOCAL, p.kind());
        assertEquals("my-bucket", p.s3Bucket());
        assertEquals("folder/file.yml", p.s3Key());
        assertEquals("local-import/my-bucket/folder/file.yml", WorkAreaProposalPathCodec.syntheticRepoRelativePath(p));
    }

    @Test
    void pathCodecRejectsBadPrefix() {
        assertThrows(IllegalArgumentException.class, () -> WorkAreaProposalPathCodec.parse("BUCKET/x/y"));
    }
}
