package com.bsg.docviz.application.port.output;

/**
 * Borradores del área de trabajo ({@code *_vN.*.txt}) y archivos versionados aceptados.
 */
public interface WorkAreaDraftFilePort {

    int nextDraftVersion(String sourceRelativePath);

    void writeDraftTxt(String draftRelativePath, String mergeBody);

    String acceptDraft(String draftTxtRelativePath);

    /**
     * Como {@link #acceptDraft(String)} pero el cuerpo del borrador viene en la petición (vista previa / conflictos en UI).
     */
    String finalizeDraftWithContent(String draftTxtRelativePath, String mergeBody);

    void writeAcceptedVersionContent(String acceptedRelativePath, String utf8);

    void deleteDraft(String draftRelativePath);

    String readRepoFileUtf8(String relativePath);
}
