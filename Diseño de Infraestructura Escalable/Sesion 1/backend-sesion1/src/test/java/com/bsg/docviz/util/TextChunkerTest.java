package com.bsg.docviz.util;

import org.junit.jupiter.api.Test;

import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

class TextChunkerTest {

    @Test
    void blankReturnsEmpty() {
        assertTrue(TextChunker.chunk(null, 100, 10).isEmpty());
        assertTrue(TextChunker.chunk("   ", 100, 10).isEmpty());
    }

    @Test
    void nonPositiveChunkSizeReturnsSinglePart() {
        List<String> parts = TextChunker.chunk("hello", 0, 0);
        assertEquals(1, parts.size());
        assertEquals("hello", parts.get(0));
    }

    @Test
    void chunksWithOverlap() {
        String text = "abcdefghij";
        List<String> parts = TextChunker.chunk(text, 4, 1);
        assertEquals(3, parts.size());
        assertEquals("abcd", parts.get(0));
        assertEquals("defg", parts.get(1));
        assertEquals("ghij", parts.get(2));
    }
}
