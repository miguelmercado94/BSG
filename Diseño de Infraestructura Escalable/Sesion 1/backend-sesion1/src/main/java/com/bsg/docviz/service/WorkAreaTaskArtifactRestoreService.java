package com.bsg.docviz.service;

import com.bsg.docviz.application.port.output.SessionRegistryPort;
import com.bsg.docviz.application.port.output.WorkAreaDraftFilePort;
import com.bsg.docviz.context.DocvizTaskContext;
import com.bsg.docviz.domain.workspace.WorkspaceS3KeyBuilder;
import com.bsg.docviz.dto.RestoredWorkAreaProposalDto;
import com.bsg.docviz.dto.TaskArtifactRestoreResponse;
import com.bsg.docviz.security.CurrentUser;
import com.bsg.docviz.security.DocvizUserFilter;
import com.bsg.docviz.vector.VectorIngestService;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.List;

/**
 * Restaura borradores y copias workarea desde S3 al working tree (tras «Continuar en workspace»).
 */
@Service
public class WorkAreaTaskArtifactRestoreService {

    private final WorkAreaS3ArtifactService workAreaS3ArtifactService;
    private final WorkAreaDraftFilePort workAreaDraftFileService;
    private final SessionRegistryPort sessionRegistry;
    private final WorkspaceS3KeyBuilder workspaceS3KeyBuilder;
    private final VectorIngestService vectorIngestService;

    public WorkAreaTaskArtifactRestoreService(
            WorkAreaS3ArtifactService workAreaS3ArtifactService,
            WorkAreaDraftFilePort workAreaDraftFileService,
            SessionRegistryPort sessionRegistry,
            WorkspaceS3KeyBuilder workspaceS3KeyBuilder,
            VectorIngestService vectorIngestService) {
        this.workAreaS3ArtifactService = workAreaS3ArtifactService;
        this.workAreaDraftFileService = workAreaDraftFileService;
        this.sessionRegistry = sessionRegistry;
        this.workspaceS3KeyBuilder = workspaceS3KeyBuilder;
        this.vectorIngestService = vectorIngestService;
    }

    public TaskArtifactRestoreResponse restoreFromS3() {
        if (!sessionRegistry.current().isConnected()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "No hay sesión Git conectada");
        }
        String taskHu = DocvizTaskContext.taskLabelOrNull();
        if (taskHu == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Falta cabecera " + DocvizUserFilter.TASK_HU_HEADER);
        }
        if (!workAreaS3ArtifactService.isS3Configured()) {
            return new TaskArtifactRestoreResponse(List.of(), List.of(), List.of());
        }
        String userId = CurrentUser.require();
        String ns = vectorIngestService.currentNamespace();
        String borradoresPrefix = workspaceS3KeyBuilder.borradoresPrefix(ns, taskHu, userId);
        String workareaPrefix = workspaceS3KeyBuilder.workareaPrefix(ns, taskHu, userId);

        List<String> borradores = new ArrayList<>();
        List<String> workarea = new ArrayList<>();
        List<RestoredWorkAreaProposalDto> proposals = new ArrayList<>();

        for (String key : workAreaS3ArtifactService.listBorradorObjectKeys(userId, taskHu)) {
            if (!key.startsWith(borradoresPrefix) || key.length() <= borradoresPrefix.length()) {
                continue;
            }
            String suffix = key.substring(borradoresPrefix.length()).replace('\\', '/');
            if (suffix.isBlank()) {
                continue;
            }
            try {
                byte[] raw = workAreaS3ArtifactService.getBorradorObjectBytes(key);
                String utf8 = new String(raw, StandardCharsets.UTF_8);
                String diskRel = draftRelativePathForRestore(suffix);
                workAreaDraftFileService.writeDraftTxt(diskRel, utf8);
                borradores.add(diskRel);
                proposals.add(toDraftProposal(diskRel, utf8));
            } catch (RuntimeException e) {
                /* siguiente clave */
            }
        }

        for (String key : workAreaS3ArtifactService.listWorkareaObjectKeys(userId, taskHu)) {
            if (!key.startsWith(workareaPrefix) || key.length() <= workareaPrefix.length()) {
                continue;
            }
            String suffix = key.substring(workareaPrefix.length()).replace('\\', '/');
            if (suffix.isBlank()) {
                continue;
            }
            try {
                byte[] raw = workAreaS3ArtifactService.getWorkareaObjectBytes(key);
                String utf8 = new String(raw, StandardCharsets.UTF_8);
                workAreaDraftFileService.writeAcceptedVersionContent(suffix, utf8);
                workarea.add(suffix);
                proposals.add(toAcceptedProposal(suffix, utf8));
            } catch (RuntimeException e) {
                /* siguiente clave */
            }
        }

        return new TaskArtifactRestoreResponse(List.copyOf(borradores), List.copyOf(workarea), List.copyOf(proposals));
    }

    private static RestoredWorkAreaProposalDto toDraftProposal(String suffix, String content) {
        String fn = fileName(suffix);
        int dot = fn.lastIndexOf('.');
        String ext = dot > 0 ? fn.substring(dot + 1) : "";
        String id = "s3-restore-draft-" + suffix.replace('/', '_');
        return new RestoredWorkAreaProposalDto(id, fn, ext, content, suffix, null);
    }

    private static RestoredWorkAreaProposalDto toAcceptedProposal(String suffix, String content) {
        String fn = fileName(suffix);
        int dot = fn.lastIndexOf('.');
        String ext = dot > 0 ? fn.substring(dot + 1) : "";
        String id = "s3-restore-wa-" + suffix.replace('/', '_');
        return new RestoredWorkAreaProposalDto(id, fn, ext, content, null, suffix);
    }

    private static String fileName(String relativePath) {
        String n = relativePath.replace('\\', '/').trim();
        int i = n.lastIndexOf('/');
        return i >= 0 ? n.substring(i + 1) : n;
    }

    /**
     * Objetos nuevos en S3 usan hoja {@code *_vN.ext}; en disco el borrador sigue siendo {@code *_vN.ext.txt}.
     * Objetos antiguos con {@code .txt} en la clave se escriben tal cual.
     */
    private static String draftRelativePathForRestore(String suffixAfterPrefix) {
        String s = suffixAfterPrefix.replace('\\', '/').trim();
        String leaf = fileName(s);
        if (leaf.endsWith(".txt")) {
            return s;
        }
        if (leaf.matches("(?i).+_v\\d+\\..+")) {
            if (s.contains("/")) {
                return s.substring(0, s.lastIndexOf('/') + 1) + leaf + ".txt";
            }
            return leaf + ".txt";
        }
        return s;
    }
}
