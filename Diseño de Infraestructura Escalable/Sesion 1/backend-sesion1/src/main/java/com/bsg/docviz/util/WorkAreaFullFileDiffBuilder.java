package com.bsg.docviz.util;

import com.bsg.docviz.dto.WorkAreaDiffLineDto;
import com.github.difflib.DiffUtils;
import com.github.difflib.patch.AbstractDelta;
import com.github.difflib.patch.DeltaType;
import com.github.difflib.patch.Patch;

import java.util.ArrayList;
import java.util.List;

/**
 * Construye una lista de líneas etiquetadas (context / removed / added) para <strong>todo</strong> el archivo,
 * a partir del original y del texto revisado (Myers), para el visor del área de trabajo.
 */
public final class WorkAreaFullFileDiffBuilder {

    private WorkAreaFullFileDiffBuilder() {}

    public static List<WorkAreaDiffLineDto> buildFullDiffLines(String originalText, String revisedText) {
        List<String> orig = WorkAreaPartialDiffApplier.splitLines(originalText);
        List<String> rev = WorkAreaPartialDiffApplier.splitLines(revisedText);
        if (orig.isEmpty() && rev.isEmpty()) {
            return List.of();
        }
        Patch<String> patch = DiffUtils.diff(orig, rev);
        List<WorkAreaDiffLineDto> out = new ArrayList<>();
        int o = 0;
        for (AbstractDelta<String> delta : patch.getDeltas()) {
            int pos = delta.getSource().getPosition();
            while (o < pos) {
                out.add(line("context", orig.get(o)));
                o++;
            }
            DeltaType type = delta.getType();
            if (type == DeltaType.INSERT) {
                for (String line : delta.getTarget().getLines()) {
                    out.add(line("added", line));
                }
            } else if (type == DeltaType.DELETE) {
                for (String line : delta.getSource().getLines()) {
                    out.add(line("removed", line));
                }
                o += delta.getSource().getLines().size();
            } else if (type == DeltaType.CHANGE) {
                for (String line : delta.getSource().getLines()) {
                    out.add(line("removed", line));
                }
                for (String line : delta.getTarget().getLines()) {
                    out.add(line("added", line));
                }
                o += delta.getSource().getLines().size();
            } else if (type == DeltaType.EQUAL) {
                for (String line : delta.getSource().getLines()) {
                    out.add(line("context", line));
                    o++;
                }
            }
        }
        while (o < orig.size()) {
            out.add(line("context", orig.get(o)));
            o++;
        }
        return out;
    }

    private static WorkAreaDiffLineDto line(String kind, String text) {
        WorkAreaDiffLineDto d = new WorkAreaDiffLineDto();
        d.setKind(kind);
        d.setText(text != null ? text : "");
        return d;
    }
}
