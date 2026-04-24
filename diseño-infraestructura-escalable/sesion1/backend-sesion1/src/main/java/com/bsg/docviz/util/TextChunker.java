package com.bsg.docviz.util;

import java.util.ArrayList;
import java.util.List;

public final class TextChunker {

    private TextChunker() {
    }

    public static List<String> chunk(String text, int chunkSize, int overlap) {
        if (text == null || text.isBlank()) {
            return List.of();
        }
        if (chunkSize <= 0) {
            return List.of(text);
        }
        int ov = Math.max(0, Math.min(overlap, chunkSize - 1));
        List<String> out = new ArrayList<>();
        int i = 0;
        while (i < text.length()) {
            int end = Math.min(i + chunkSize, text.length());
            out.add(text.substring(i, end));
            if (end >= text.length()) {
                break;
            }
            i = end - ov;
            if (i < 0) {
                i = end;
            }
        }
        return out;
    }
}
