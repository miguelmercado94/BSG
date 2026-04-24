package com.bsg.docviz.service;

import com.bsg.docviz.application.port.output.FileExplorerPort;
import com.bsg.docviz.application.port.output.WorkAreaDraftFilePort;
import com.bsg.docviz.dto.WorkAreaChangeBlockDto;
import com.bsg.docviz.util.WorkAreaContextHunkApplier;
import com.bsg.docviz.util.WorkAreaDraftPathBuilder;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.util.ArrayList;
import java.util.List;

/**
 * Aplica cambios revisados en UI (sin borrador {@code .txt} en disco): solo hunks aceptados o texto final ya resuelto.
 */
@Service
public class WorkAreaReviewApplyService {

    private final FileExplorerPort fileExplorerService;
    private final WorkAreaDraftFilePort workAreaDraftFileService;

    public WorkAreaReviewApplyService(
            FileExplorerPort fileExplorerService, WorkAreaDraftFilePort workAreaDraftFileService) {
        this.fileExplorerService = fileExplorerService;
        this.workAreaDraftFileService = workAreaDraftFileService;
    }

    /**
     * Aplica únicamente los bloques con {@code accepted[i] == true}; el resultado se escribe en {@code *_vN.ext}.
     */
    public String applyReviewedChangeBlocks(
            String sourcePath, int draftVersion, List<WorkAreaChangeBlockDto> changeBlocks, List<Boolean> accepted) {
        if (changeBlocks == null || accepted == null || changeBlocks.size() != accepted.size()) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST, "changeBlocks y accepted deben tener la misma longitud");
        }
        List<WorkAreaChangeBlockDto> toApply = new ArrayList<>();
        for (int i = 0; i < changeBlocks.size(); i++) {
            if (Boolean.TRUE.equals(accepted.get(i))) {
                toApply.add(changeBlocks.get(i));
            }
        }
        if (toApply.isEmpty()) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Ningún cambio aceptado: use «Descartar» si no desea guardar nada en el repositorio.");
        }
        String rel = WorkAreaDraftPathBuilder.normalizeSourceRelativePath(sourcePath);
        boolean onlyCreate =
                toApply.size() == 1
                        && "create_file".equalsIgnoreCase(String.valueOf(toApply.get(0).getType()).trim());
        String original = "";
        if (!onlyCreate) {
            original = fileExplorerService.readFile(rel).getContent();
        }
        String result;
        try {
            result = WorkAreaContextHunkApplier.apply(original, toApply);
        } catch (IllegalArgumentException ex) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    ex.getMessage()
                            + " Si ya tiene el archivo completo resuelto, use POST /vector/work-area/apply-final con "
                            + "finalContent, o POST /vector/work-area/apply-review con el campo finalContent, "
                            + "o POST /vector/work-area/draft/finalize con el texto del borrador.",
                    ex);
        }
        String draftTxt = WorkAreaDraftPathBuilder.buildDraftTxtPath(rel, draftVersion);
        String acceptedRel = WorkAreaDraftPathBuilder.acceptedPathFromDraftTxt(draftTxt);
        workAreaDraftFileService.writeAcceptedVersionContent(acceptedRel, result);
        return acceptedRel;
    }

    public String applyFinalContent(String sourcePath, int draftVersion, String finalContent) {
        String rel = WorkAreaDraftPathBuilder.normalizeSourceRelativePath(sourcePath);
        String draftTxt = WorkAreaDraftPathBuilder.buildDraftTxtPath(rel, draftVersion);
        String acceptedRel = WorkAreaDraftPathBuilder.acceptedPathFromDraftTxt(draftTxt);
        workAreaDraftFileService.writeAcceptedVersionContent(acceptedRel, finalContent);
        return acceptedRel;
    }
}
