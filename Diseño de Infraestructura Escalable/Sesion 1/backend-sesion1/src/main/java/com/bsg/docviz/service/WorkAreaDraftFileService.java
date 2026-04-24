package com.bsg.docviz.service;

import com.bsg.docviz.application.port.output.SessionRegistryPort;
import com.bsg.docviz.application.port.output.WorkAreaDraftFilePort;
import com.bsg.docviz.context.DocvizTaskContext;
import com.bsg.docviz.security.CurrentUser;
import com.bsg.docviz.util.WorkAreaDraftPathBuilder;
import com.bsg.docviz.util.WorkAreaDraftVersionResolver;
import com.bsg.docviz.util.WorkAreaMergeConflictFormatter;
import com.bsg.docviz.util.WorkAreaMergeConflictParser;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;

/**
 * Escribe borradores {@code *_vN.*.txt} en el working tree del repo y aplica aceptación (quita .txt, escribe versión final).
 * <p>
 * S3: con soporte habilitado, el borrador se sincroniza bajo el prefijo {@code borrador/} (plantilla
 * {@code docviz.workspace-s3.borradores-prefix-template}). Al finalizar/aceptar se borra ese objeto y se escribe la
 * copia aceptada en {@code workarea/}; la indexación vectorial vuelve a actualizar {@code workarea/} y limpia cualquier
 * borrador {@code .txt} restante en S3.
 * </p>
 */
@Service
public class WorkAreaDraftFileService implements WorkAreaDraftFilePort {

    private static final Logger log = LoggerFactory.getLogger(WorkAreaDraftFileService.class);

    private final SessionRegistryPort sessionRegistry;
    private final WorkAreaS3ArtifactService workAreaS3ArtifactService;

    public WorkAreaDraftFileService(SessionRegistryPort sessionRegistry, WorkAreaS3ArtifactService workAreaS3ArtifactService) {
        this.sessionRegistry = sessionRegistry;
        this.workAreaS3ArtifactService = workAreaS3ArtifactService;
    }

    public int nextDraftVersion(String sourceRelativePath) {
        Path root = sessionRegistry.current().getRepositoryRoot();
        if (root == null) {
            throw new IllegalStateException("Not connected to a repository");
        }
        return WorkAreaDraftVersionResolver.nextVersion(root, sourceRelativePath);
    }

    public void writeDraftTxt(String draftRelativePath, String mergeBody) {
        Path abs = resolveSafe(draftRelativePath);
        try {
            Files.createDirectories(abs.getParent());
            Files.writeString(abs, mergeBody, StandardCharsets.UTF_8);
            log.info(
                    "Borrador área de trabajo escrito: path={} chars={}",
                    draftRelativePath,
                    mergeBody != null ? mergeBody.length() : 0);
            workAreaS3ArtifactService.syncDraft(
                    CurrentUser.require(),
                    DocvizTaskContext.taskLabelOrDefault(),
                    draftRelativePath,
                    mergeBody);
        } catch (IOException e) {
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "No se pudo escribir el borrador: " + e.getMessage());
        }
    }

    /**
     * Lee el .txt, extrae el texto propuesto, escribe {@code *_V1.ext} y elimina el .txt.
     *
     * @return ruta relativa del archivo aceptado (sin .txt)
     */
    public String acceptDraft(String draftTxtRelativePath) {
        Path draftAbs = resolveSafe(draftTxtRelativePath);
        if (!draftTxtRelativePath.endsWith(".txt")) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Se esperaba un borrador .txt");
        }
        if (!Files.isRegularFile(draftAbs)) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "No existe el borrador: " + draftTxtRelativePath);
        }
        String mergeBody;
        try {
            mergeBody = Files.readString(draftAbs, StandardCharsets.UTF_8);
        } catch (IOException e) {
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "No se pudo leer el borrador");
        }
        return finalizeDraftWithContent(draftTxtRelativePath, mergeBody);
    }

    @Override
    public String finalizeDraftWithContent(String draftTxtRelativePath, String mergeBody) {
        if (!draftTxtRelativePath.endsWith(".txt")) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Se esperaba un borrador .txt");
        }
        if (mergeBody == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "El contenido no puede ser nulo");
        }
        if (WorkAreaMergeConflictFormatter.hasConflictMarkers(mergeBody)) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Resuelve todos los bloques de merge en el borrador antes de guardar (no debe quedar «"
                            + WorkAreaMergeConflictFormatter.MARKER_OURS
                            + "»).");
        }
        if (mergeBody.contains("<<<<<<<")) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST, "Aún hay marcadores de conflicto («<<<<<<<») sin resolver.");
        }
        String revised;
        if (mergeBody.contains(WorkAreaMergeConflictFormatter.MARKER_DIV)) {
            revised = WorkAreaMergeConflictParser.extractRevised(mergeBody);
            if (revised.isEmpty()) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "No se pudo extraer el bloque propuesto del borrador");
            }
        } else {
            revised = mergeBody.trim();
            if (revised.isEmpty()) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "El borrador está vacío");
            }
        }
        Path draftAbs = resolveSafe(draftTxtRelativePath);
        String acceptedRel = WorkAreaDraftPathBuilder.acceptedPathFromDraftTxt(draftTxtRelativePath);
        Path acceptedAbs = resolveSafe(acceptedRel);
        try {
            Files.createDirectories(acceptedAbs.getParent());
            Files.writeString(acceptedAbs, revised, StandardCharsets.UTF_8);
            Files.deleteIfExists(draftAbs);
        } catch (IOException e) {
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "No se pudo aceptar el borrador: " + e.getMessage());
        }
        workAreaS3ArtifactService.deleteDraftArtifact(
                CurrentUser.require(),
                DocvizTaskContext.taskLabelOrDefault(),
                draftTxtRelativePath);
        workAreaS3ArtifactService.syncAccepted(
                CurrentUser.require(),
                DocvizTaskContext.taskLabelOrDefault(),
                acceptedRel,
                revised);
        log.info("Borrador finalizado: {} → {}", draftTxtRelativePath, acceptedRel);
        return acceptedRel;
    }

    /**
     * Escribe la copia versionada {@code *_vN.ext} (sin paso intermedio {@code .txt}), p. ej. tras revisión en UI desde JSON.
     */
    public void writeAcceptedVersionContent(String acceptedRelativePath, String utf8) {
        Path abs = resolveSafe(acceptedRelativePath);
        try {
            Files.createDirectories(abs.getParent());
            Files.writeString(abs, utf8 == null ? "" : utf8, StandardCharsets.UTF_8);
            workAreaS3ArtifactService.syncAccepted(
                    CurrentUser.require(),
                    DocvizTaskContext.taskLabelOrDefault(),
                    acceptedRelativePath,
                    utf8 == null ? "" : utf8);
            log.info("Copia versionada escrita (sin .txt previo): {}", acceptedRelativePath);
        } catch (IOException e) {
            throw new ResponseStatusException(
                    HttpStatus.INTERNAL_SERVER_ERROR, "No se pudo escribir el archivo: " + e.getMessage());
        }
    }

    public void deleteDraft(String draftRelativePath) {
        Path abs = resolveSafe(draftRelativePath);
        try {
            Files.deleteIfExists(abs);
        } catch (IOException e) {
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "No se pudo borrar: " + e.getMessage());
        }
        workAreaS3ArtifactService.deleteDraftArtifact(
                CurrentUser.require(),
                DocvizTaskContext.taskLabelOrDefault(),
                draftRelativePath);
    }

    public String readRepoFileUtf8(String relativePath) {
        Path abs = resolveSafe(relativePath);
        if (!Files.isRegularFile(abs)) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Archivo no encontrado: " + relativePath);
        }
        try {
            return Files.readString(abs, StandardCharsets.UTF_8);
        } catch (IOException e) {
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "No se pudo leer el archivo");
        }
    }

    private Path resolveSafe(String relativePath) {
        var session = sessionRegistry.current();
        if (!session.isConnected()) {
            throw new IllegalStateException("Not connected to a repository");
        }
        Path root = session.getRepositoryRoot();
        if (root == null) {
            throw new IllegalStateException("Not connected to a repository");
        }
        String rel = WorkAreaDraftPathBuilder.normalizeRelPath(relativePath);
        if (rel.isBlank() || rel.contains("..")) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Ruta inválida");
        }
        Path resolved = root.resolve(rel).normalize();
        if (!resolved.startsWith(root.normalize())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Ruta fuera del repositorio");
        }
        return resolved;
    }
}
