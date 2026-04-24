package com.bsg.docviz.service;

import com.bsg.docviz.application.port.output.FileExplorerPort;
import com.bsg.docviz.application.port.output.SessionRegistryPort;
import com.bsg.docviz.application.port.output.WorkAreaDraftFilePort;
import com.bsg.docviz.dto.WorkAreaChangeBlockDto;
import com.bsg.docviz.dto.WorkAreaDiffLineDto;
import com.bsg.docviz.dto.WorkAreaLineEditDto;
import com.bsg.docviz.dto.WorkAreaProposalItemDto;
import com.bsg.docviz.dto.WorkAreaYamlProposalBlockDto;
import com.bsg.docviz.util.WorkAreaContextHunkApplier;
import com.bsg.docviz.util.WorkAreaDraftPathBuilder;
import com.bsg.docviz.util.WorkAreaFullFileDiffBuilder;
import com.bsg.docviz.util.WorkAreaLineRangeApplier;
import com.bsg.docviz.util.WorkAreaMergeConflictFormatter;
import com.bsg.docviz.util.WorkAreaPartialDiffApplier;
import com.bsg.docviz.support.SupportS3Service;
import com.bsg.docviz.util.WorkAreaProposalContentHeuristics;
import com.bsg.docviz.util.WorkAreaProposalMerger;
import com.bsg.docviz.util.WorkAreaRepoFileSanitizer;
import com.bsg.docviz.util.WorkAreaRepoPathResolver;
import com.bsg.docviz.util.WorkAreaYamlBlockLineApplier;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.nio.charset.StandardCharsets;
import java.util.List;

/**
 * Enriquece propuestas: rellena {@code content} con texto estilo {@code git merge} (marcadores DocViz) para el visor
 * de conflicto; {@code diffLines} es opcional para otros usos.
 */
@Service
public class WorkAreaProposalEnrichmentService {

    private static final Logger log = LoggerFactory.getLogger(WorkAreaProposalEnrichmentService.class);

    private final FileExplorerPort fileExplorerService;
    private final WorkAreaDraftFilePort workAreaDraftFileService;
    private final SessionRegistryPort sessionRegistry;
    private final ObjectProvider<SupportS3Service> supportS3;

    public WorkAreaProposalEnrichmentService(
            FileExplorerPort fileExplorerService,
            WorkAreaDraftFilePort workAreaDraftFileService,
            SessionRegistryPort sessionRegistry,
            ObjectProvider<SupportS3Service> supportS3) {
        this.fileExplorerService = fileExplorerService;
        this.workAreaDraftFileService = workAreaDraftFileService;
        this.sessionRegistry = sessionRegistry;
        this.supportS3 = supportS3;
    }

    public void enrichFromRepository(List<WorkAreaProposalItemDto> proposals) {
        if (proposals == null || proposals.isEmpty()) {
            return;
        }
        String rootLabel = sessionRegistry.current().getRootFolderLabel();
        List<WorkAreaProposalItemDto> collapsed =
                WorkAreaProposalMerger.collapseBySourcePath(proposals, rootLabel);
        proposals.clear();
        proposals.addAll(collapsed);
        for (WorkAreaProposalItemDto p : proposals) {
            String src = p.getSourcePath();
            if (src == null || src.isBlank()) {
                log.warn(
                        "WorkArea enrich: propuesta sin sourcePath (fileName={}), no se crea borrador",
                        p.getFileName());
                clearYamlTransportFields(p);
                continue;
            }
            String originalRead = null;
            try {
                var repoState = sessionRegistry.current();
                String normalized = WorkAreaDraftPathBuilder.normalizeSourceRelativePath(src);
                p.setSourcePath(normalized);

                boolean createOnly = isCreateFileOnly(p);
                boolean localS3 = "LOCAL".equalsIgnoreCase(p.getProposalOriginKind());
                log.info(
                        "WorkArea borrador: createFileOnly={} localS3={} para normalizedSourcePath={}",
                        createOnly,
                        localS3,
                        normalized);
                String original;
                if (createOnly) {
                    String label = repoState.getRootFolderLabel();
                    p.setSourcePath(WorkAreaRepoPathResolver.stripUiRootFolderPrefix(normalized, label));
                    original = "";
                } else if (localS3) {
                    original = readLocalS3ProposalUtf8(p);
                    log.info("WorkArea borrador: original LOCAL S3 chars={}", original.length());
                } else {
                    try {
                        original = readOriginalForProposal(p, normalized, repoState);
                    } catch (ResponseStatusException ex) {
                        if (ex.getStatusCode() == HttpStatus.NOT_FOUND && Boolean.TRUE.equals(p.getYamlNewFile())) {
                            original = "";
                            String label = repoState.getRootFolderLabel();
                            p.setSourcePath(WorkAreaRepoPathResolver.stripUiRootFolderPrefix(normalized, label));
                            log.info(
                                    "WorkArea borrador: yaml new:true y archivo ausente → original vacío rel={}",
                                    p.getSourcePath());
                        } else {
                            throw ex;
                        }
                    }
                }
                originalRead = original;
                String rel = p.getSourcePath();
                int ver = workAreaDraftFileService.nextDraftVersion(rel);
                p.setDraftVersion(ver);
                String draftRel = WorkAreaDraftPathBuilder.buildDraftTxtPath(rel, ver);
                log.info(
                        "WorkArea borrador nombramiento: sourcePathRaw={} repoRel={} draftVersion={} draftRel={} "
                                + "revisionSpec={} ephemeralManagedClone={}",
                        src,
                        rel,
                        ver,
                        draftRel,
                        repoState.getRevisionSpec(),
                        repoState.isEphemeralManagedClone());
                applyDraftDisplayName(p, draftRel);
                log.info(
                        "WorkArea borrador UI: fileName={} extension={}",
                        p.getFileName(),
                        p.getExtension());
                if (!createOnly && original.length() > FileContentCache.MAX_SINGLE_FILE_BYTES) {
                    log.debug("WorkArea enrich: archivo demasiado grande, vista previa mínima ({})", rel);
                    p.setContent(
                            "/* DocViz: el archivo supera el límite de vista previa en el servidor. "
                                    + "Conecta el cliente o revisa el modelo. */\n");
                    p.setDraftRelativePath(null);
                    continue;
                }
                String originalForMerge = WorkAreaRepoFileSanitizer.stripDocvizMergeMarkerLines(original);
                if (!originalForMerge.equals(original)) {
                    log.warn(
                            "WorkArea borrador: se eliminaron líneas de marcadores <<<<<<< / ======= / >>>>>>> del archivo leído del repo "
                                    + "(posible copia corrupta). rel={}",
                            rel);
                }
                String revised = resolveRevisedText(originalForMerge, p);
                List<WorkAreaDiffLineDto> full = WorkAreaFullFileDiffBuilder.buildFullDiffLines(originalForMerge, revised);
                p.setDiffLines(full);
                String mergeDisplay = WorkAreaMergeConflictFormatter.format(originalForMerge, revised);
                p.setContent(mergeDisplay);
                workAreaDraftFileService.writeDraftTxt(draftRel, mergeDisplay);
                p.setDraftRelativePath(draftRel);
                log.info(
                        "WorkArea borrador: escrito {} y sincronizado a S3 (borradores) draftVersion={} contentChars={} originalChars={} revisedChars={}",
                        draftRel,
                        ver,
                        mergeDisplay.length(),
                        originalForMerge.length(),
                        revised.length());
            } catch (ResponseStatusException ex) {
                log.warn(
                        "WorkArea enrich: fallo HTTP al preparar borrador sourcePathRaw={} normalizedRel={} — {} ({})",
                        src,
                        WorkAreaDraftPathBuilder.normalizeSourceRelativePath(src),
                        ex.getStatusCode(),
                        ex.getReason());
                applyFallbackContent(p, originalRead, "HTTP " + ex.getStatusCode() + ": " + ex.getReason());
            } catch (RuntimeException ex) {
                log.warn(
                        "WorkArea enrich: omitido sourcePathRaw={} normalizedRel={}",
                        src,
                        WorkAreaDraftPathBuilder.normalizeSourceRelativePath(src),
                        ex);
                applyFallbackContent(p, originalRead, ex.getClass().getSimpleName() + ": " + ex.getMessage());
            } finally {
                clearYamlTransportFields(p);
            }
        }
    }

    private String readLocalS3ProposalUtf8(WorkAreaProposalItemDto p) {
        SupportS3Service s3 = supportS3.getIfAvailable();
        if (s3 == null) {
            throw new ResponseStatusException(
                    HttpStatus.SERVICE_UNAVAILABLE,
                    "S3 no disponible: no se puede leer propuesta LOCAL (configura docviz.support + workspace-s3).");
        }
        String bucket = p.getLocalS3Bucket();
        String key = p.getLocalS3ObjectKey();
        if (bucket == null || bucket.isBlank() || key == null || key.isBlank()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Propuesta LOCAL sin bucket o key S3");
        }
        try {
            byte[] raw = s3.getObjectBytes(bucket, key.trim());
            return new String(raw, StandardCharsets.UTF_8);
        } catch (RuntimeException ex) {
            throw new ResponseStatusException(
                    HttpStatus.NOT_FOUND,
                    "No se pudo leer el objeto S3 " + bucket + "/" + key,
                    ex);
        }
    }

    private static void clearYamlTransportFields(WorkAreaProposalItemDto p) {
        p.setYamlBlocks(null);
        p.setProposalOriginKind(null);
        p.setLocalS3Bucket(null);
        p.setLocalS3ObjectKey(null);
        p.setYamlNewFile(null);
    }

    /**
     * Garantiza {@code content} no vacío: texto revisado vía {@link #resolveRevisedText} y cabecera opcional si hubo error.
     */
    private void applyFallbackContent(WorkAreaProposalItemDto p, String originalOrNull, String errorHint) {
        if (p.getContent() != null && !p.getContent().isBlank()) {
            return;
        }
        String o = originalOrNull != null ? originalOrNull : "";
        try {
            if (p.getDraftVersion() == null && p.getSourcePath() != null && !p.getSourcePath().isBlank()) {
                String rel = p.getSourcePath();
                int ver = workAreaDraftFileService.nextDraftVersion(rel);
                p.setDraftVersion(ver);
                String draftRel = WorkAreaDraftPathBuilder.buildDraftTxtPath(rel, ver);
                applyDraftDisplayName(p, draftRel);
            }
        } catch (RuntimeException ex) {
            log.debug("WorkArea fallback: draftVersion/display: {}", ex.getMessage());
        }
        String oSan = WorkAreaRepoFileSanitizer.stripDocvizMergeMarkerLines(o);
        String revised = resolveRevisedText(oSan, p);
        String safeHint = errorHint == null ? "" : errorHint.replace("*/", "* /");
        String header =
                safeHint.isBlank()
                        ? ""
                        : "/* DocViz: vista generada en modo recuperación. "
                                + safeHint
                                + " */\n\n";
        p.setContent(header + WorkAreaMergeConflictFormatter.format(oSan, revised));
        p.setDiffLines(WorkAreaFullFileDiffBuilder.buildFullDiffLines(oSan, revised));
        p.setDraftRelativePath(null);
    }

    /** Nombre mostrado como copia versionada {@code *_vN.ext} (sin {@code .txt} intermedio). */
    private static void applyDraftDisplayName(WorkAreaProposalItemDto p, String draftTxtRelativePath) {
        String acceptedRel = WorkAreaDraftPathBuilder.acceptedPathFromDraftTxt(draftTxtRelativePath);
        String base =
                acceptedRel.contains("/")
                        ? acceptedRel.substring(acceptedRel.lastIndexOf('/') + 1)
                        : acceptedRel;
        p.setFileName(base);
        int dot = base.lastIndexOf('.');
        p.setExtension(dot > 0 ? base.substring(dot + 1) : "");
    }

    /**
     * Intenta primero la ruta sin prefijo de carpeta UI ({@code findu/}…); si el blob no existe, reintenta con la ruta
     * tal cual vino del modelo (por si el repo sí tiene ese prefijo en el árbol Git).
     */
    private String readOriginalForProposal(WorkAreaProposalItemDto p, String normalized, UserRepositoryState repo) {
        String label = repo.getRootFolderLabel();
        String stripped = WorkAreaRepoPathResolver.stripUiRootFolderPrefix(normalized, label);
        log.info("WorkArea borrador: leyendo original strippedRel={} fallbackNormalized={}", stripped, normalized);
        try {
            String content = fileExplorerService.readFile(stripped).getContent();
            p.setSourcePath(stripped);
            log.info("WorkArea borrador: original leído OK rel={} chars={}", stripped, content != null ? content.length() : 0);
            return content;
        } catch (ResponseStatusException ex) {
            if (ex.getStatusCode() == HttpStatus.NOT_FOUND && !stripped.equals(normalized)) {
                log.info("WorkArea borrador: 404 con stripped, reintento con ruta completa rel={}", normalized);
                String content = fileExplorerService.readFile(normalized).getContent();
                p.setSourcePath(normalized);
                log.info("WorkArea borrador: original leído OK rel={} chars={}", normalized, content != null ? content.length() : 0);
                return content;
            }
            throw ex;
        }
    }

    private static boolean isCreateFileOnly(WorkAreaProposalItemDto p) {
        List<WorkAreaChangeBlockDto> ch = p.getChangeBlocks();
        if (ch == null || ch.size() != 1) {
            return false;
        }
        String t = ch.get(0).getType();
        return t != null && "create_file".equalsIgnoreCase(t.trim());
    }

    /**
     * Prioridad: ediciones estructuradas ({@code changeBlocks}, {@code lineEdits}, {@code diffLines}) antes que
     * sustituir por el {@code content} completo del ítem, para alinear el backend con propuestas “quirúrgicas” del LLM.
     * El reemplazo por archivo entero vía {@code content} queda como compatibilidad cuando no hay bloques o fallan.
     */
    static String resolveRevisedText(String original, WorkAreaProposalItemDto p) {
        String o = original == null ? "" : original;
        String contentField = p.getContent();

        List<WorkAreaYamlProposalBlockDto> yamlBlocks = p.getYamlBlocks();
        if (yamlBlocks != null && !yamlBlocks.isEmpty()) {
            try {
                return WorkAreaYamlBlockLineApplier.apply(o, yamlBlocks);
            } catch (IllegalArgumentException ex) {
                log.warn("WorkArea yaml blocks: {}", ex.getMessage());
            }
        }

        List<WorkAreaChangeBlockDto> changeBlocks = p.getChangeBlocks();
        if (changeBlocks != null && !changeBlocks.isEmpty()) {
            try {
                return WorkAreaContextHunkApplier.apply(o, changeBlocks);
            } catch (IllegalArgumentException ex) {
                log.warn("WorkArea changeBlocks: {}", ex.getMessage());
            }
        }
        List<WorkAreaLineEditDto> lineEdits = p.getLineEdits();
        if (lineEdits != null && !lineEdits.isEmpty()) {
            try {
                return WorkAreaLineRangeApplier.apply(o, lineEdits);
            } catch (IllegalArgumentException ex) {
                log.warn("WorkArea lineEdits: {}", ex.getMessage());
            }
        }
        List<WorkAreaDiffLineDto> dl = p.getDiffLines();
        if (dl != null && !dl.isEmpty()) {
            return WorkAreaPartialDiffApplier.apply(o, dl);
        }
        // Archivo nuevo: solo texto completo en el ítem (sin changeBlocks)
        if (o.isEmpty() && contentField != null && !contentField.isBlank()) {
            if (WorkAreaProposalContentHeuristics.looksLikeInvalidYamlStub(contentField, o)) {
                log.warn("WorkArea: content parece resumen inválido para archivo nuevo; se deja vacío.");
                return o;
            }
            return contentField;
        }
        if (WorkAreaProposalContentHeuristics.shouldPreferFullFileContent(contentField, o)) {
            return contentField;
        }
        if (contentField != null && !contentField.isBlank()) {
            if (WorkAreaProposalContentHeuristics.looksLikeInvalidYamlStub(contentField, o)) {
                log.warn(
                        "WorkArea: el campo content del modelo parece un resumen inválido (p. ej. lista de servicios); "
                                + "no se aplica como borrador.");
                return o;
            }
            return contentField;
        }
        return o;
    }
}
