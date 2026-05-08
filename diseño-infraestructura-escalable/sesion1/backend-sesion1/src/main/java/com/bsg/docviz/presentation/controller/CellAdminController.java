package com.bsg.docviz.presentation.controller;

import com.bsg.docviz.dto.CellRepoAssignRequest;
import com.bsg.docviz.dto.CellRepoRequest;
import com.bsg.docviz.dto.CellRepoResponse;
import com.bsg.docviz.dto.CellRepoUrlHintResponse;
import com.bsg.docviz.dto.CellRequest;
import com.bsg.docviz.dto.CellResponse;
import com.bsg.docviz.dto.DeleteImpactResponse;
import com.bsg.docviz.dto.FileContentResponse;
import com.bsg.docviz.dto.FolderStructureDto;
import com.bsg.docviz.dto.GitConnectionMode;
import com.bsg.docviz.dto.IngestProgressDto;
import com.bsg.docviz.dto.SupportMarkdownUpdateRequest;
import com.bsg.docviz.dto.SupportMarkdownUploadResponse;
import com.bsg.docviz.security.CurrentUser;
import com.bsg.docviz.service.DomainCellService;
import com.bsg.docviz.support.SupportMarkdownService;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.validation.Valid;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.web.servlet.mvc.method.annotation.StreamingResponseBody;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.IOException;
import java.io.OutputStreamWriter;
import java.io.UncheckedIOException;
import java.io.Writer;
import java.nio.charset.StandardCharsets;
import java.util.List;

@RestController
@RequestMapping("/admin/cells")
public class CellAdminController {

    private static final Logger log = LoggerFactory.getLogger(CellAdminController.class);

    private final DomainCellService domainCellService;
    private final ObjectMapper objectMapper;
    private final ObjectProvider<SupportMarkdownService> supportMarkdownService;

    public CellAdminController(
            DomainCellService domainCellService,
            ObjectMapper objectMapper,
            ObjectProvider<SupportMarkdownService> supportMarkdownService) {
        this.domainCellService = domainCellService;
        this.objectMapper = objectMapper;
        this.supportMarkdownService = supportMarkdownService;
    }

    /** Listado (mismo cuerpo que {@code GET /cells}); evita 405 si algo hace GET sobre {@code /admin/cells}. */
    @GetMapping
    public List<CellResponse> list() {
        return domainCellService.listCells();
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public CellResponse create(@Valid @RequestBody CellRequest body) {
        return domainCellService.createCell(body);
    }

    @PutMapping("/{id}")
    public CellResponse update(@PathVariable long id, @Valid @RequestBody CellRequest body) {
        return domainCellService.updateCell(id, body);
    }

    /** Tareas que se borrarán en cascada al eliminar la célula (confirmación en UI). */
    @GetMapping("/{id}/delete-impact")
    public DeleteImpactResponse deleteImpactCell(@PathVariable long id) {
        return new DeleteImpactResponse(domainCellService.countTasksForCellDelete(id));
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable long id) {
        domainCellService.deleteCell(id);
    }

    /**
     * Sugiere nombre y namespace a partir de la URL. Ruta canónica {@code /hints/repo-url}; se mantiene
     * {@code /repo-url-hint} para clientes en caché. Ambas son GET explícitos (no usan {@code /{id}}).
     */
    @GetMapping({"/hints/repo-url", "/repo-url-hint"})
    public CellRepoUrlHintResponse repoUrlHint(
            @RequestParam(required = false) String url,
            @RequestParam(required = false) String localPath,
            @RequestParam GitConnectionMode mode) {
        return domainCellService.previewRepoUrl(url, localPath, mode);
    }

    @PostMapping("/{cellId}/repos")
    @ResponseStatus(HttpStatus.CREATED)
    public CellRepoResponse createRepo(@PathVariable long cellId, @Valid @RequestBody CellRepoRequest body) {
        return domainCellService.createRepo(cellId, body);
    }

    /** Asigna repositorios ya indexados (huérfanos) a la célula tras “Guardar” en el editor. */
    @PostMapping("/{cellId}/repos/assign")
    public List<CellRepoResponse> assignRepos(
            @PathVariable long cellId, @Valid @RequestBody CellRepoAssignRequest body) {
        List<Long> ids = body.repoIds() != null ? body.repoIds() : List.of();
        return domainCellService.assignOrphansToCell(cellId, ids);
    }

    /**
     * Indexa un repositorio sin célula (pendiente de “Guardar”). NDJSON como {@code /{cellId}/repos/stream}.
     * Ruta bajo {@code /admin/cells/...} para convivir con el mismo controlador y despliegues que ya exponen este prefijo.
     */
    @PostMapping(value = "/pending/index/stream", produces = "application/x-ndjson")
    @ResponseStatus(HttpStatus.CREATED)
    public ResponseEntity<StreamingResponseBody> indexOrphanStream(@Valid @RequestBody CellRepoRequest body) {
        final String userId = CurrentUser.require();
        StreamingResponseBody stream =
                outputStream -> {
                    CurrentUser.set(userId);
                    try (Writer w = new OutputStreamWriter(outputStream, StandardCharsets.UTF_8)) {
                        try {
                            domainCellService.indexRepoOrphan(
                                    body,
                                    ev -> {
                                        try {
                                            w.write(objectMapper.writeValueAsString(ev));
                                            w.write("\n");
                                            w.flush();
                                        } catch (IOException e) {
                                            throw new UncheckedIOException(e);
                                        }
                                    });
                        } catch (Exception e) {
                            log.error("POST /admin/cells/pending/index/stream falló: {}", e.toString(), e);
                            String msg = e.getMessage() != null ? e.getMessage() : e.toString();
                            if (e instanceof ResponseStatusException rse) {
                                msg = rse.getReason() != null ? rse.getReason() : msg;
                            }
                            try {
                                w.write(objectMapper.writeValueAsString(IngestProgressDto.error(msg)));
                                w.write("\n");
                                w.flush();
                            } catch (IOException ignored) {
                                // cliente cerró
                            }
                        }
                    } finally {
                        CurrentUser.clear();
                    }
                };
        return ResponseEntity.status(HttpStatus.CREATED)
                .header(HttpHeaders.CACHE_CONTROL, "no-store")
                .header("X-Accel-Buffering", "no")
                .contentType(MediaType.parseMediaType("application/x-ndjson"))
                .body(stream);
    }

    @DeleteMapping("/pending/{repoId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void deletePendingOrphan(@PathVariable long repoId) {
        domainCellService.deleteOrphanRepo(repoId);
    }

    @GetMapping("/pending/{repoId}/tree")
    public FolderStructureDto pendingRepoTree(@PathVariable long repoId) {
        return domainCellService.getPendingRepoFolderStructure(repoId);
    }

    @GetMapping(value = "/pending/{repoId}/file", produces = MediaType.APPLICATION_JSON_VALUE)
    public FileContentResponse pendingRepoFile(@PathVariable long repoId, @RequestParam("path") String path) {
        return domainCellService.getPendingRepoFileContent(repoId, path);
    }

    /**
     * Misma creación que {@link #createRepo(long, CellRepoRequest)} pero con NDJSON de progreso de indexación
     * (START, FILE, PROGRESS, DONE, CELL_REPO_READY).
     */
    @PostMapping(value = "/{cellId}/repos/stream", produces = "application/x-ndjson")
    @ResponseStatus(HttpStatus.CREATED)
    public ResponseEntity<StreamingResponseBody> createRepoStream(
            @PathVariable long cellId, @Valid @RequestBody CellRepoRequest body) {
        final String userId = CurrentUser.require();
        StreamingResponseBody stream = outputStream -> {
            CurrentUser.set(userId);
            try (Writer w = new OutputStreamWriter(outputStream, StandardCharsets.UTF_8)) {
                try {
                    domainCellService.createRepo(cellId, body, ev -> {
                        try {
                            w.write(objectMapper.writeValueAsString(ev));
                            w.write("\n");
                            w.flush();
                        } catch (IOException e) {
                            throw new UncheckedIOException(e);
                        }
                    });
                } catch (Exception e) {
                    log.error("POST /admin/cells/{}/repos/stream falló: {}", cellId, e.toString(), e);
                    String msg = e.getMessage() != null ? e.getMessage() : e.toString();
                    if (e instanceof ResponseStatusException rse) {
                        msg = rse.getReason() != null ? rse.getReason() : msg;
                    }
                    try {
                        w.write(objectMapper.writeValueAsString(IngestProgressDto.error(msg)));
                        w.write("\n");
                        w.flush();
                    } catch (IOException ignored) {
                        // cliente cerró
                    }
                }
            } finally {
                CurrentUser.clear();
            }
        };
        return ResponseEntity.status(HttpStatus.CREATED)
                .header(HttpHeaders.CACHE_CONTROL, "no-store")
                .header("X-Accel-Buffering", "no")
                .contentType(MediaType.parseMediaType("application/x-ndjson"))
                .body(stream);
    }

    @PutMapping("/{cellId}/repos/{repoId}")
    public CellRepoResponse updateRepo(
            @PathVariable long cellId,
            @PathVariable long repoId,
            @Valid @RequestBody CellRepoRequest body) {
        return domainCellService.updateRepo(cellId, repoId, body);
    }

    /** Tareas vinculadas al repo que se eliminarían al borrarlo. */
    @GetMapping("/{cellId}/repos/{repoId}/delete-impact")
    public DeleteImpactResponse deleteImpactRepo(
            @PathVariable long cellId, @PathVariable long repoId) {
        return new DeleteImpactResponse(domainCellService.countTasksForRepoDelete(cellId, repoId));
    }

    @DeleteMapping("/{cellId}/repos/{repoId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void deleteRepo(@PathVariable long cellId, @PathVariable long repoId) {
        domainCellService.deleteRepo(cellId, repoId);
    }

    /** Árbol de archivos del repositorio (clon efímero) para el panel admin. */
    @GetMapping("/{cellId}/repos/{repoId}/tree")
    public FolderStructureDto adminRepoTree(@PathVariable long cellId, @PathVariable long repoId) {
        return domainCellService.getAdminRepoFolderStructure(cellId, repoId);
    }

    /** Contenido de un archivo del repo (solo lectura). */
    @GetMapping(value = "/{cellId}/repos/{repoId}/file", produces = MediaType.APPLICATION_JSON_VALUE)
    public FileContentResponse adminRepoFile(
            @PathVariable long cellId,
            @PathVariable long repoId,
            @RequestParam("path") String path) {
        return domainCellService.getAdminRepoFileContent(cellId, repoId, path);
    }

    @PostMapping(value = "/{cellId}/repos/{repoId}/support/markdown", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public SupportMarkdownUploadResponse adminSupportUpload(
            @PathVariable long cellId,
            @PathVariable long repoId,
            @RequestParam("file") MultipartFile file,
            @RequestParam("huCode") String huCode,
            @RequestParam("huTitle") String huTitle) {
        domainCellService.assertRepoBelongsToCell(cellId, repoId);
        SupportMarkdownService svc = supportMarkdownService.getIfAvailable();
        if (svc == null) {
            throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE, "Soporte Markdown deshabilitado");
        }
        return svc.uploadAndIndexForCellRepo(repoId, file, huCode, huTitle);
    }

    @DeleteMapping("/{cellId}/repos/{repoId}/support/markdown")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void adminSupportDelete(
            @PathVariable long cellId,
            @PathVariable long repoId,
            @RequestParam("fileName") String fileName) {
        domainCellService.assertRepoBelongsToCell(cellId, repoId);
        SupportMarkdownService svc = supportMarkdownService.getIfAvailable();
        if (svc == null) {
            throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE, "Soporte Markdown deshabilitado");
        }
        svc.deleteForCellRepo(repoId, fileName);
    }

    @PutMapping("/{cellId}/repos/{repoId}/support/markdown")
    public SupportMarkdownUploadResponse adminSupportUpdate(
            @PathVariable long cellId,
            @PathVariable long repoId,
            @Valid @RequestBody SupportMarkdownUpdateRequest body) {
        domainCellService.assertRepoBelongsToCell(cellId, repoId);
        SupportMarkdownService svc = supportMarkdownService.getIfAvailable();
        if (svc == null) {
            throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE, "Soporte Markdown deshabilitado");
        }
        return svc.updateForCellRepo(repoId, body.fileName(), body.content());
    }

    @PostMapping(value = "/pending/{repoId}/support/markdown", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public SupportMarkdownUploadResponse pendingSupportUpload(
            @PathVariable long repoId,
            @RequestParam("file") MultipartFile file,
            @RequestParam("huCode") String huCode,
            @RequestParam("huTitle") String huTitle) {
        domainCellService.assertPendingOrphanRepo(repoId);
        SupportMarkdownService svc = supportMarkdownService.getIfAvailable();
        if (svc == null) {
            throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE, "Soporte Markdown deshabilitado");
        }
        return svc.uploadAndIndexForCellRepo(repoId, file, huCode, huTitle);
    }

    @DeleteMapping("/pending/{repoId}/support/markdown")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void pendingSupportDelete(@PathVariable long repoId, @RequestParam("fileName") String fileName) {
        domainCellService.assertPendingOrphanRepo(repoId);
        SupportMarkdownService svc = supportMarkdownService.getIfAvailable();
        if (svc == null) {
            throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE, "Soporte Markdown deshabilitado");
        }
        svc.deleteForCellRepo(repoId, fileName);
    }

    @PutMapping("/pending/{repoId}/support/markdown")
    public SupportMarkdownUploadResponse pendingSupportUpdate(
            @PathVariable long repoId, @Valid @RequestBody SupportMarkdownUpdateRequest body) {
        domainCellService.assertPendingOrphanRepo(repoId);
        SupportMarkdownService svc = supportMarkdownService.getIfAvailable();
        if (svc == null) {
            throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE, "Soporte Markdown deshabilitado");
        }
        return svc.updateForCellRepo(repoId, body.fileName(), body.content());
    }
}
