package com.bsg.docviz.presentation.controller;

import com.bsg.docviz.context.DocvizTaskContext;
import com.bsg.docviz.dto.S3FileUrlItem;
import com.bsg.docviz.dto.VectorIngestResponse;
import com.bsg.docviz.dto.WorkAreaApplyFinalBody;
import com.bsg.docviz.dto.WorkAreaApplyReviewedBody;
import com.bsg.docviz.dto.WorkAreaDraftAcceptAllBody;
import com.bsg.docviz.dto.WorkAreaDraftFinalizeBody;
import com.bsg.docviz.dto.WorkAreaDraftPathBody;
import com.bsg.docviz.dto.WorkAreaIndexFileBody;
import com.bsg.docviz.dto.WorkAreaS3WorkareaSaveRequest;
import com.bsg.docviz.application.port.output.WorkAreaDraftFilePort;
import com.bsg.docviz.dto.TaskArtifactRestoreResponse;
import com.bsg.docviz.security.CurrentUser;
import com.bsg.docviz.security.DocvizUserFilter;
import com.bsg.docviz.service.WorkAreaReviewApplyService;
import com.bsg.docviz.service.WorkAreaS3ArtifactService;
import com.bsg.docviz.service.WorkAreaTaskArtifactRestoreService;
import com.bsg.docviz.vector.VectorIngestService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/vector/work-area")
public class WorkAreaDraftController {

    private final WorkAreaDraftFilePort workAreaDraftFileService;
    private final VectorIngestService vectorIngestService;
    private final WorkAreaReviewApplyService workAreaReviewApplyService;
    private final WorkAreaTaskArtifactRestoreService workAreaTaskArtifactRestoreService;
    private final WorkAreaS3ArtifactService workAreaS3ArtifactService;

    public WorkAreaDraftController(
            WorkAreaDraftFilePort workAreaDraftFileService,
            VectorIngestService vectorIngestService,
            WorkAreaReviewApplyService workAreaReviewApplyService,
            WorkAreaTaskArtifactRestoreService workAreaTaskArtifactRestoreService,
            WorkAreaS3ArtifactService workAreaS3ArtifactService) {
        this.workAreaDraftFileService = workAreaDraftFileService;
        this.vectorIngestService = vectorIngestService;
        this.workAreaReviewApplyService = workAreaReviewApplyService;
        this.workAreaTaskArtifactRestoreService = workAreaTaskArtifactRestoreService;
        this.workAreaS3ArtifactService = workAreaS3ArtifactService;
    }

    /**
     * Lista objetos en S3 (borradores o workarea) con URL presignada; el front descarga sin pasar el cuerpo por la API.
     * Requiere cabecera {@link DocvizUserFilter#TASK_HU_HEADER} como en el resto del área de trabajo.
     */
    @GetMapping("/s3-objects")
    public List<S3FileUrlItem> listS3Objects(@RequestParam("kind") String kind) {
        String taskHu = DocvizTaskContext.taskLabelOrNull();
        if (taskHu == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Falta cabecera " + DocvizUserFilter.TASK_HU_HEADER);
        }
        if (!workAreaS3ArtifactService.isS3Configured()) {
            return List.of();
        }
        String userId = CurrentUser.require();
        if ("borradores".equalsIgnoreCase(kind) || "borrador".equalsIgnoreCase(kind)) {
            return workAreaS3ArtifactService.listBorradoresWithUrls(userId, taskHu);
        }
        if ("workarea".equalsIgnoreCase(kind)) {
            return workAreaS3ArtifactService.listWorkareaWithUrls(userId, taskHu);
        }
        throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "kind debe ser borrador(es) o workarea");
    }

    /**
     * Lista en un solo JSON los objetos de borradores y workarea con URL presignada.
     * {@code userId} debe coincidir con el usuario autenticado; {@code taskHu} con la cabecera de tarea HU.
     */
    @GetMapping("/s3-artifacts")
    public List<S3FileUrlItem> listS3Artifacts(
            @RequestParam("userId") String userId, @RequestParam("taskHu") String taskHu) {
        String current = CurrentUser.require();
        if (!current.equals(userId)) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "userId no coincide con la sesión");
        }
        String ctxHu = DocvizTaskContext.taskLabelOrNull();
        if (ctxHu == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Falta cabecera " + DocvizUserFilter.TASK_HU_HEADER);
        }
        if (!ctxHu.equals(taskHu)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "taskHu debe coincidir con la cabecera de tarea");
        }
        if (!workAreaS3ArtifactService.isS3Configured()) {
            return List.of();
        }
        return workAreaS3ArtifactService.listBorradoresAndWorkareaWithUrls(userId, taskHu);
    }

    /**
     * Cuerpo UTF-8 de un objeto borrador/workarea (mismo origen que la SPA vía proxy; evita CORS del GET presignado a
     * LocalStack). Requiere cabecera HU; {@code bucket} y {@code key} deben coincidir con el prefijo del usuario/tarea.
     */
    @GetMapping(value = "/s3-artifact-body", produces = MediaType.TEXT_PLAIN_VALUE)
    public ResponseEntity<String> getS3ArtifactBody(
            @RequestParam("bucket") String bucket, @RequestParam("key") String key) {
        String taskHu = DocvizTaskContext.taskLabelOrNull();
        if (taskHu == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Falta cabecera " + DocvizUserFilter.TASK_HU_HEADER);
        }
        if (!workAreaS3ArtifactService.isS3Configured()) {
            throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE, "S3 no configurado");
        }
        byte[] raw = workAreaS3ArtifactService.getArtifactBytesIfOwned(CurrentUser.require(), taskHu, bucket, key);
        return ResponseEntity.ok(new String(raw, StandardCharsets.UTF_8));
    }

    /**
     * Elimina un objeto borrador o workarea si la clave pertenece al usuario y HU de la cabecera.
     */
    @DeleteMapping("/s3-artifact")
    public ResponseEntity<Map<String, Boolean>> deleteS3Artifact(
            @RequestParam("bucket") String bucket, @RequestParam("key") String key) {
        String taskHu = DocvizTaskContext.taskLabelOrNull();
        if (taskHu == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Falta cabecera " + DocvizUserFilter.TASK_HU_HEADER);
        }
        if (!workAreaS3ArtifactService.isS3Configured()) {
            throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE, "S3 no configurado");
        }
        workAreaS3ArtifactService.deleteArtifactIfOwned(CurrentUser.require(), taskHu, bucket, key);
        return ResponseEntity.ok(Map.of("deleted", Boolean.TRUE));
    }

    /**
     * Actualiza el cuerpo de un objeto en el bucket workarea y reindexa en pgvector (misma fuente RAG que POST
     * /vector/work-area/ingest).
     */
    @PostMapping("/s3-workarea-save")
    public ResponseEntity<VectorIngestResponse> saveWorkareaS3AndReindex(@Valid @RequestBody WorkAreaS3WorkareaSaveRequest body) {
        String taskHu = DocvizTaskContext.taskLabelOrNull();
        if (taskHu == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Falta cabecera " + DocvizUserFilter.TASK_HU_HEADER);
        }
        if (!workAreaS3ArtifactService.isS3Configured()) {
            throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE, "S3 no configurado");
        }
        VectorIngestResponse out =
                workAreaS3ArtifactService.updateWorkareaObjectReindex(
                        CurrentUser.require(), taskHu, body.getObjectKey(), body.getContent());
        return ResponseEntity.ok(out);
    }

    /**
     * Actualiza el cuerpo de un objeto en el bucket borradores (sin reindexar). Para borradores listados solo-S3 con
     * conflictos DocViz resueltos en la SPA.
     */
    @PostMapping("/s3-borrador-save")
    public ResponseEntity<Map<String, Boolean>> saveBorradorS3(@Valid @RequestBody WorkAreaS3WorkareaSaveRequest body) {
        String taskHu = DocvizTaskContext.taskLabelOrNull();
        if (taskHu == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Falta cabecera " + DocvizUserFilter.TASK_HU_HEADER);
        }
        if (!workAreaS3ArtifactService.isS3Configured()) {
            throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE, "S3 no configurado");
        }
        workAreaS3ArtifactService.updateBorradorObjectContent(
                CurrentUser.require(), taskHu, body.getObjectKey(), body.getContent());
        return ResponseEntity.ok(Map.of("saved", Boolean.TRUE));
    }

    /**
     * Restaura borradores y archivos workarea desde S3 al clon (cabeceras {@code X-DocViz-Task-Hu} y opcionalmente
     * {@code X-DocViz-Cell} como en el resto del área de trabajo).
     */
    @PostMapping("/restore-s3")
    public ResponseEntity<TaskArtifactRestoreResponse> restoreFromS3() {
        return ResponseEntity.ok(workAreaTaskArtifactRestoreService.restoreFromS3());
    }

    /**
     * Acepta un borrador .txt: escribe {@code *_V1.ext} con el contenido propuesto y borra el .txt. No indexa.
     */
    @PostMapping("/draft/accept")
    public ResponseEntity<Map<String, String>> acceptDraft(@Valid @RequestBody WorkAreaDraftPathBody body) {
        String accepted = workAreaDraftFileService.acceptDraft(body.getDraftRelativePath());
        return ResponseEntity.ok(Map.of("acceptedRelativePath", accepted));
    }

    /**
     * Escribe la copia aceptada en el clon y en workarea S3, elimina el borrador local y en S3. El texto viene del cliente
     * (p. ej. tras resolver conflictos en la UI), no solo del archivo en disco.
     */
    @PostMapping("/draft/finalize")
    public ResponseEntity<Map<String, String>> finalizeDraft(@Valid @RequestBody WorkAreaDraftFinalizeBody body) {
        String accepted =
                workAreaDraftFileService.finalizeDraftWithContent(
                        body.getDraftRelativePath(), body.getFinalContent());
        return ResponseEntity.ok(Map.of("acceptedRelativePath", accepted));
    }

    /**
     * Aplica hunks aceptados desde la UI (JSON del LLM), o escribe {@code finalContent} si viene relleno
     * (evita errores de ancla cuando los hunks no calzan con el archivo real).
     */
    @PostMapping("/apply-review")
    public ResponseEntity<Map<String, String>> applyReviewed(@RequestBody WorkAreaApplyReviewedBody body) {
        if (body.getSourcePath() == null || body.getSourcePath().isBlank()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "sourcePath es obligatorio");
        }
        if (body.getDraftVersion() == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "draftVersion es obligatorio");
        }
        String fc = body.getFinalContent();
        if (fc != null && !fc.trim().isEmpty()) {
            String accepted =
                    workAreaReviewApplyService.applyFinalContent(
                            body.getSourcePath(), body.getDraftVersion(), fc);
            return ResponseEntity.ok(Map.of("acceptedRelativePath", accepted));
        }
        if (body.getChangeBlocks() == null
                || body.getAccepted() == null
                || body.getChangeBlocks().size() != body.getAccepted().size()) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Sin finalContent: changeBlocks y accepted son obligatorios y deben tener la misma longitud");
        }
        String accepted =
                workAreaReviewApplyService.applyReviewedChangeBlocks(
                        body.getSourcePath(),
                        body.getDraftVersion(),
                        body.getChangeBlocks(),
                        body.getAccepted());
        return ResponseEntity.ok(Map.of("acceptedRelativePath", accepted));
    }

    /** Escribe {@code *_vN.ext} con el texto ya resuelto (p. ej. un solo bloque tipo merge en la vista). */
    @PostMapping("/apply-final")
    public ResponseEntity<Map<String, String>> applyFinal(@Valid @RequestBody WorkAreaApplyFinalBody body) {
        String accepted =
                workAreaReviewApplyService.applyFinalContent(
                        body.getSourcePath(), body.getDraftVersion(), body.getFinalContent());
        return ResponseEntity.ok(Map.of("acceptedRelativePath", accepted));
    }

    @PostMapping("/draft/accept-all")
    public ResponseEntity<Map<String, Object>> acceptAll(@Valid @RequestBody WorkAreaDraftAcceptAllBody body) {
        List<String> accepted = new ArrayList<>();
        for (String p : body.getDraftRelativePaths()) {
            accepted.add(workAreaDraftFileService.acceptDraft(p));
        }
        return ResponseEntity.ok(Map.of("acceptedRelativePaths", accepted));
    }

    /**
     * Lee el cuerpo UTF-8 de un borrador {@code .txt} (o cualquier ruta bajo la raíz del repo conectado).
     * Permite a la SPA mostrar la vista previa si el mensaje WebSocket no incluyó {@code content}.
     */
    @GetMapping("/draft")
    public ResponseEntity<Map<String, String>> getDraft(@RequestParam("path") String path) {
        String content = workAreaDraftFileService.readRepoFileUtf8(path);
        return ResponseEntity.ok(Map.of("content", content));
    }

    @DeleteMapping("/draft")
    public ResponseEntity<Map<String, Boolean>> deleteDraft(@RequestParam("path") String path) {
        workAreaDraftFileService.deleteDraft(path);
        return ResponseEntity.ok(Map.of("deleted", Boolean.TRUE));
    }

    /**
     * Indexa un archivo del working tree (p. ej. copia aceptada {@code Foo_V1.java}) en el namespace vectorial.
     * Tras la ingesta, sincroniza S3 {@code workarea/} y elimina el borrador {@code .txt} homólogo en {@code borrador/}.
     */
    @PostMapping("/index-file")
    public ResponseEntity<VectorIngestResponse> indexFile(@Valid @RequestBody WorkAreaIndexFileBody body) {
        String rel = body.getRelativePath();
        String text = workAreaDraftFileService.readRepoFileUtf8(rel);
        String name = rel.contains("/") ? rel.substring(rel.lastIndexOf('/') + 1) : rel;
        VectorIngestResponse out = vectorIngestService.ingestWorkAreaFile(name, text);
        workAreaS3ArtifactService.afterWorkAreaFileIndexed(
                CurrentUser.require(), DocvizTaskContext.taskLabelOrDefault(), rel, text);
        return ResponseEntity.ok(out);
    }
}
