package com.bsg.docviz.dto;

/**
 * Resultado de indexar una única ruta relativa (flujo admin archivo por archivo).
 */
public record SinglePathIngestResult(
        boolean indexed,
        boolean skipped,
        String path,
        int chunksIndexed,
        String skipReason,
        String errorMessage
) {
    public static SinglePathIngestResult indexed(String path, int chunksIndexed) {
        return new SinglePathIngestResult(true, false, path, chunksIndexed, null, null);
    }

    public static SinglePathIngestResult skipped(String path, String skipReason) {
        return new SinglePathIngestResult(false, true, path, 0, skipReason, null);
    }

    public static SinglePathIngestResult failed(String path, String errorMessage) {
        return new SinglePathIngestResult(false, false, path, 0, null, errorMessage);
    }
}
