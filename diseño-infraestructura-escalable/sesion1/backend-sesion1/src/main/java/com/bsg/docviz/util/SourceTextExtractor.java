package com.bsg.docviz.util;

import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.text.PDFTextStripper;

import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.nio.charset.Charset;
import java.nio.charset.CodingErrorAction;
import java.nio.charset.StandardCharsets;

public final class SourceTextExtractor {

    private SourceTextExtractor() {
    }

    public static String extractText(String path, byte[] raw) {
        if (raw == null || raw.length == 0) {
            return "";
        }
        String lower = path.toLowerCase();
        if (lower.endsWith(".pdf")) {
            try (PDDocument doc = PDDocument.load(new ByteArrayInputStream(raw))) {
                PDFTextStripper stripper = new PDFTextStripper();
                return stripper.getText(doc);
            } catch (IOException e) {
                return "";
            }
        }
        return decodeAsUtf8WithFallback(raw);
    }

    private static String decodeAsUtf8WithFallback(byte[] raw) {
        try {
            Charset utf8 = StandardCharsets.UTF_8;
            return utf8.newDecoder()
                    .onMalformedInput(CodingErrorAction.REPLACE)
                    .onUnmappableCharacter(CodingErrorAction.REPLACE)
                    .decode(java.nio.ByteBuffer.wrap(raw))
                    .toString();
        } catch (Exception e) {
            return new String(raw, StandardCharsets.ISO_8859_1);
        }
    }
}
