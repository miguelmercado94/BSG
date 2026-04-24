package com.bsg.docviz.dto;



import jakarta.validation.constraints.NotBlank;



import java.util.List;



/**

 * POST /vector/work-area/apply-review — aplica hunks aceptados, o bien escribe texto ya resuelto.

 *

 * <p>Si {@link #finalContent} viene relleno, se ignora el parche por hunks (mismo efecto que {@code /apply-final}).

 */

public class WorkAreaApplyReviewedBody {



    @NotBlank

    private String sourcePath;



    private Integer draftVersion;



    private List<WorkAreaChangeBlockDto> changeBlocks;



    /** Misma longitud que {@link #changeBlocks}; {@code true} = aplicar ese hunk. */

    private List<Boolean> accepted;



    /** Texto UTF-8 completo ya resuelto (sin marcadores). Si no es nulo/vacío, no se usan {@link #changeBlocks}. */

    private String finalContent;



    public String getSourcePath() {

        return sourcePath;

    }



    public void setSourcePath(String sourcePath) {

        this.sourcePath = sourcePath;

    }



    public Integer getDraftVersion() {

        return draftVersion;

    }



    public void setDraftVersion(Integer draftVersion) {

        this.draftVersion = draftVersion;

    }



    public List<WorkAreaChangeBlockDto> getChangeBlocks() {

        return changeBlocks;

    }



    public void setChangeBlocks(List<WorkAreaChangeBlockDto> changeBlocks) {

        this.changeBlocks = changeBlocks;

    }



    public List<Boolean> getAccepted() {

        return accepted;

    }



    public void setAccepted(List<Boolean> accepted) {

        this.accepted = accepted;

    }



    public String getFinalContent() {

        return finalContent;

    }



    public void setFinalContent(String finalContent) {

        this.finalContent = finalContent;

    }

}


