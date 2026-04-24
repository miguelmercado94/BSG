package com.bsg.docviz.util;

/**
 * Extrae original y revisado de un borrador con marcadores DocViz (orden nuevo: tras el primer {@code =======} viene
 * {@code >>>>>>> SUGGESTION} y el texto propuesto, cerrado con otro {@code =======}), o legado (texto propuesto antes
 * del marcador {@code >>>>>>>}).
 */
public final class WorkAreaMergeConflictParser {

    private WorkAreaMergeConflictParser() {}

    public static String extractRevised(String mergeFileBody) {
        if (mergeFileBody == null || mergeFileBody.isEmpty()) {
            return "";
        }
        String ours = findOursMarker(mergeFileBody);
        if (ours == null) {
            return "";
        }
        int oursIdx = mergeFileBody.indexOf(ours);
        int afterOursLine = mergeFileBody.indexOf('\n', oursIdx);
        if (afterOursLine < 0) {
            return "";
        }
        afterOursLine++;
        int firstDiv = mergeFileBody.indexOf(WorkAreaMergeConflictFormatter.MARKER_DIV, afterOursLine);
        if (firstDiv < 0) {
            return "";
        }
        int afterFirstDivLine = mergeFileBody.indexOf('\n', firstDiv);
        if (afterFirstDivLine < 0) {
            afterFirstDivLine = firstDiv + WorkAreaMergeConflictFormatter.MARKER_DIV.length();
        } else {
            afterFirstDivLine++;
        }
        int pos = skipBlankLines(mergeFileBody, afterFirstDivLine);
        if (pos < mergeFileBody.length() && mergeFileBody.startsWith(">>>>>>>", pos)) {
            int theirsLineEnd = mergeFileBody.indexOf('\n', pos);
            if (theirsLineEnd < 0) {
                return "";
            }
            int revStart = theirsLineEnd + 1;
            int closeDiv = indexOfLineExactly(mergeFileBody, WorkAreaMergeConflictFormatter.MARKER_DIV, revStart);
            if (closeDiv < 0) {
                return trimTrailNl(mergeFileBody.substring(revStart));
            }
            return trimTrailNl(mergeFileBody.substring(revStart, closeDiv));
        }
        int theirsIdx = indexOfTheirs(mergeFileBody, afterFirstDivLine);
        if (theirsIdx < 0) {
            return "";
        }
        String chunk = mergeFileBody.substring(afterFirstDivLine, theirsIdx);
        return trimTrailNl(chunk);
    }

    public static String extractOriginal(String mergeFileBody) {
        if (mergeFileBody == null || mergeFileBody.isEmpty()) {
            return "";
        }
        String ours = findOursMarker(mergeFileBody);
        if (ours == null) {
            return "";
        }
        int start = mergeFileBody.indexOf(ours);
        int contentStart = mergeFileBody.indexOf('\n', start);
        if (contentStart < 0) {
            return "";
        }
        contentStart++;
        int div = mergeFileBody.indexOf(WorkAreaMergeConflictFormatter.MARKER_DIV, contentStart);
        if (div < 0) {
            return "";
        }
        String chunk = mergeFileBody.substring(contentStart, div);
        return trimTrailNl(chunk);
    }

    private static String findOursMarker(String body) {
        if (body.contains(WorkAreaMergeConflictFormatter.MARKER_OURS)) {
            return WorkAreaMergeConflictFormatter.MARKER_OURS;
        }
        if (body.contains(WorkAreaMergeConflictFormatter.LEGACY_MARKER_OURS)) {
            return WorkAreaMergeConflictFormatter.LEGACY_MARKER_OURS;
        }
        return null;
    }

    private static int indexOfTheirs(String s, int from) {
        int a = s.indexOf(WorkAreaMergeConflictFormatter.MARKER_THEIRS, from);
        int b = s.indexOf(WorkAreaMergeConflictFormatter.LEGACY_MARKER_THEIRS, from);
        if (a < 0) {
            return b;
        }
        if (b < 0) {
            return a;
        }
        return Math.min(a, b);
    }

    private static int skipBlankLines(String s, int from) {
        int i = from;
        int n = s.length();
        while (i < n) {
            char c = s.charAt(i);
            if (c == '\n' || c == '\r') {
                i++;
            } else if (c == ' ' || c == '\t') {
                i++;
            } else {
                break;
            }
        }
        return i;
    }

    /** Primera línea (desde {@code from}) cuyo trim es exactamente {@code marker}. */
    private static int indexOfLineExactly(String s, String marker, int from) {
        int i = from;
        int n = s.length();
        while (i < n) {
            int lineEnd = s.indexOf('\n', i);
            int end = lineEnd < 0 ? n : lineEnd;
            String line = s.substring(i, end).trim();
            if (marker.equals(line)) {
                return i;
            }
            if (lineEnd < 0) {
                break;
            }
            i = lineEnd + 1;
        }
        return -1;
    }

    private static String trimTrailNl(String chunk) {
        if (chunk == null || chunk.isEmpty()) {
            return "";
        }
        if (chunk.endsWith("\r\n")) {
            return chunk.substring(0, chunk.length() - 2);
        }
        if (chunk.endsWith("\n") || chunk.endsWith("\r")) {
            return chunk.substring(0, chunk.length() - 1);
        }
        return chunk;
    }
}
