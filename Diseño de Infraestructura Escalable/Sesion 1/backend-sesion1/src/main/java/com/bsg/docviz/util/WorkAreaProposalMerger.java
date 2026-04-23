package com.bsg.docviz.util;

import com.bsg.docviz.dto.WorkAreaChangeBlockDto;
import com.bsg.docviz.dto.WorkAreaDiffLineDto;
import com.bsg.docviz.dto.WorkAreaLineEditDto;
import com.bsg.docviz.dto.WorkAreaProposalItemDto;
import com.bsg.docviz.dto.WorkAreaYamlProposalBlockDto;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Varias entradas en {@code proposals:[]} para el mismo archivo (mismo path en repo) se fusionan en una sola
 * propuesta con todos los {@code lineEdits} / {@code changeBlocks} / {@code diffLines}, para un solo borrador y un
 * solo flujo de versión S3.
 */
public final class WorkAreaProposalMerger {

    private static final Logger log = LoggerFactory.getLogger(WorkAreaProposalMerger.class);

    private WorkAreaProposalMerger() {}

    public static List<WorkAreaProposalItemDto> collapseBySourcePath(
            List<WorkAreaProposalItemDto> proposals, String rootFolderLabel) {
        if (proposals == null || proposals.isEmpty()) {
            return List.of();
        }
        if (proposals.size() == 1) {
            return new ArrayList<>(proposals);
        }
        Map<String, List<WorkAreaProposalItemDto>> groups = new LinkedHashMap<>();
        for (WorkAreaProposalItemDto p : proposals) {
            String key = mergeKey(p, rootFolderLabel);
            groups.computeIfAbsent(key, k -> new ArrayList<>()).add(p);
        }
        List<WorkAreaProposalItemDto> out = new ArrayList<>();
        for (Map.Entry<String, List<WorkAreaProposalItemDto>> e : groups.entrySet()) {
            List<WorkAreaProposalItemDto> g = e.getValue();
            if (g.size() == 1) {
                out.add(g.get(0));
            } else {
                log.info(
                        "WorkArea merge: {} propuestas con clave de repo '{}' → una sola (lineEdits/hunks acumulados)",
                        g.size(),
                        e.getKey());
                out.add(mergeGroup(g));
            }
        }
        return out;
    }

    static String mergeKey(WorkAreaProposalItemDto p, String rootFolderLabel) {
        String src = p.getSourcePath();
        if (src == null || src.isBlank()) {
            return "__nopath__/" + (p.getId() != null ? p.getId() : "x");
        }
        String n = WorkAreaDraftPathBuilder.normalizeSourceRelativePath(src);
        return WorkAreaRepoPathResolver.stripUiRootFolderPrefix(n, rootFolderLabel);
    }

    private static WorkAreaProposalItemDto mergeGroup(List<WorkAreaProposalItemDto> g) {
        WorkAreaProposalItemDto first = g.get(0);
        WorkAreaProposalItemDto m = new WorkAreaProposalItemDto();
        m.setId(first.getId());
        m.setSourcePath(first.getSourcePath());
        m.setFileName(first.getFileName());
        m.setExtension(first.getExtension());
        m.setDraftRelativePath(first.getDraftRelativePath());
        m.setDraftVersion(first.getDraftVersion());

        List<WorkAreaLineEditDto> lineEdits = new ArrayList<>();
        List<WorkAreaChangeBlockDto> changeBlocks = new ArrayList<>();
        List<WorkAreaDiffLineDto> diffLines = new ArrayList<>();
        List<WorkAreaYamlProposalBlockDto> yamlBlocks = new ArrayList<>();
        String mergedContent = null;
        boolean yamlNew = false;
        for (WorkAreaProposalItemDto p : g) {
            if (p.getLineEdits() != null) {
                lineEdits.addAll(p.getLineEdits());
            }
            if (p.getChangeBlocks() != null) {
                changeBlocks.addAll(p.getChangeBlocks());
            }
            if (p.getDiffLines() != null) {
                diffLines.addAll(p.getDiffLines());
            }
            if (p.getYamlBlocks() != null) {
                yamlBlocks.addAll(p.getYamlBlocks());
            }
            if (Boolean.TRUE.equals(p.getYamlNewFile())) {
                yamlNew = true;
            }
            if (mergedContent == null && p.getContent() != null && !p.getContent().isBlank()) {
                mergedContent = p.getContent();
            }
        }
        lineEdits.sort(Comparator.comparingInt(WorkAreaLineEditDto::getStartLine));
        if (!lineEdits.isEmpty()) {
            warnIfLineEditsOverlap(lineEdits);
        }
        m.setLineEdits(lineEdits.isEmpty() ? null : lineEdits);
        m.setChangeBlocks(changeBlocks.isEmpty() ? null : changeBlocks);
        m.setDiffLines(diffLines.isEmpty() ? null : diffLines);
        m.setYamlBlocks(yamlBlocks.isEmpty() ? null : yamlBlocks);
        m.setYamlNewFile(yamlNew ? Boolean.TRUE : null);
        m.setProposalOriginKind(first.getProposalOriginKind());
        m.setLocalS3Bucket(first.getLocalS3Bucket());
        m.setLocalS3ObjectKey(first.getLocalS3ObjectKey());
        m.setContent(mergedContent != null ? mergedContent : "");
        return m;
    }

    private static void warnIfLineEditsOverlap(List<WorkAreaLineEditDto> sorted) {
        for (int i = 1; i < sorted.size(); i++) {
            if (sorted.get(i).getStartLine() <= sorted.get(i - 1).getEndLine()) {
                log.warn(
                        "WorkArea merge: hay solape entre rangos de línea tras fusionar ({}-{} con {}-{})",
                        sorted.get(i - 1).getStartLine(),
                        sorted.get(i - 1).getEndLine(),
                        sorted.get(i).getStartLine(),
                        sorted.get(i).getEndLine());
                return;
            }
        }
    }
}
