package com.bsg.docviz.service;

import com.bsg.docviz.application.port.output.GitRepositoryPort;
import com.bsg.docviz.crypto.CredentialCryptoService;
import com.bsg.docviz.dto.CellRepoRequest;
import com.bsg.docviz.dto.CellRepoResponse;
import com.bsg.docviz.dto.CellRepoUrlHintResponse;
import com.bsg.docviz.dto.CellRequest;
import com.bsg.docviz.dto.CellResponse;
import com.bsg.docviz.dto.FileContentResponse;
import com.bsg.docviz.dto.FolderStructureDto;
import com.bsg.docviz.dto.IngestProgressDto;
import com.bsg.docviz.dto.GitConnectRequest;
import com.bsg.docviz.dto.GitConnectionMode;
import com.bsg.docviz.repository.CellEntity;
import com.bsg.docviz.repository.CellJdbcRepository;
import com.bsg.docviz.repository.CellRepoEntity;
import com.bsg.docviz.repository.CellRepoJdbcRepository;
import com.bsg.docviz.repository.TaskJdbcRepository;
import com.bsg.docviz.support.SupportS3PathBuilder;
import com.bsg.docviz.support.SupportS3Service;
import com.bsg.docviz.security.CurrentUser;
import com.bsg.docviz.util.RemoteHeadBranchResolver;
import com.bsg.docviz.util.RepositoryUrlNormalizer;
import com.bsg.docviz.dto.VectorIngestResponse;
import com.bsg.docviz.vector.VectorIngestService;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.http.HttpStatus;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.Objects;
import java.util.Optional;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;
import java.util.function.Consumer;
import java.util.stream.Collectors;

@Service
public class DomainCellService {

    private static final int NS_MAX = 500;

    private final CellJdbcRepository cellRepository;
    private final CellRepoJdbcRepository cellRepoRepository;
    private final TaskJdbcRepository taskJdbcRepository;
    private final CredentialCryptoService credentialCryptoService;
    private final GitRepositoryPort gitRepositoryService;
    private final VectorIngestService vectorIngestService;
    private final ObjectMapper objectMapper;
    private final ObjectProvider<SupportS3Service> supportS3Service;
    private final SupportS3PathBuilder supportS3PathBuilder;
    private final ConcurrentHashMap<String, Object> ingestLocks = new ConcurrentHashMap<>();

    public DomainCellService(
            CellJdbcRepository cellRepository,
            CellRepoJdbcRepository cellRepoRepository,
            TaskJdbcRepository taskJdbcRepository,
            CredentialCryptoService credentialCryptoService,
            GitRepositoryPort gitRepositoryService,
            VectorIngestService vectorIngestService,
            ObjectMapper objectMapper,
            ObjectProvider<SupportS3Service> supportS3Service,
            SupportS3PathBuilder supportS3PathBuilder) {
        this.cellRepository = cellRepository;
        this.cellRepoRepository = cellRepoRepository;
        this.taskJdbcRepository = taskJdbcRepository;
        this.credentialCryptoService = credentialCryptoService;
        this.gitRepositoryService = gitRepositoryService;
        this.vectorIngestService = vectorIngestService;
        this.objectMapper = objectMapper;
        this.supportS3Service = supportS3Service;
        this.supportS3PathBuilder = supportS3PathBuilder;
    }

    public CellRepoUrlHintResponse previewRepoUrl(String url, String localPath, GitConnectionMode mode) {
        String modeStr = mode.name();
        String key = RepositoryUrlNormalizer.normalizeRepositoryKey(url, localPath, modeStr);
        String defaultBranch = resolveDefaultBranchHint(mode, url, localPath);
        Optional<CellRepoEntity> existing = cellRepoRepository.findFirstByRepositoryKey(key);
        if (existing.isPresent()) {
            CellRepoEntity e = existing.get();
            return new CellRepoUrlHintResponse(e.displayName(), e.vectorNamespace(), true, defaultBranch);
        }
        String sourceUrl =
                mode == GitConnectionMode.LOCAL
                        ? (localPath != null ? localPath : "")
                        : (url != null ? url : "");
        String display = GitRepositoryService.slugFromGitUrl(sourceUrl);
        if (display.isBlank()) {
            display = "repo";
        }
        String ns =
                RepositoryUrlNormalizer.clampNamespace(
                        display + "__" + UUID.randomUUID().toString().replace("-", ""), NS_MAX);
        return new CellRepoUrlHintResponse(display, ns, false, defaultBranch);
    }

    private static String resolveDefaultBranchHint(GitConnectionMode mode, String url, String localPath) {
        Optional<String> o =
                mode == GitConnectionMode.LOCAL
                        ? RemoteHeadBranchResolver.forLocalPath(localPath)
                        : RemoteHeadBranchResolver.forHttpsUrl(url);
        return o.orElse(null);
    }

    public List<CellResponse> listCells() {
        return cellRepository.findAll().stream().map(this::toCellDto).collect(Collectors.toList());
    }

    public CellResponse createCell(CellRequest req) {
        String by = CurrentUser.require();
        String nameTrim = req.name().trim();
        String norm = normalizeCellIdentifier(nameTrim);
        if (norm.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "El nombre de la célula es obligatorio");
        }
        if (cellRepository.findByNormalizedName(norm).isPresent()) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Ya existe una célula con ese identificador");
        }
        long id = cellRepository.insert(nameTrim, req.description() != null ? req.description().trim() : "", by);
        return cellRepository.findById(id).map(this::toCellDto).orElseThrow();
    }

    public CellResponse updateCell(long id, CellRequest req) {
        String nameTrim = req.name().trim();
        String norm = normalizeCellIdentifier(nameTrim);
        if (norm.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "El nombre de la célula es obligatorio");
        }
        if (cellRepository.existsOtherWithNormalizedName(norm, id)) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Ya existe una célula con ese identificador");
        }
        if (!cellRepository.update(id, nameTrim, req.description() != null ? req.description().trim() : "")) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Celda no encontrada");
        }
        return cellRepository.findById(id).map(this::toCellDto).orElseThrow();
    }

    /** Mismo criterio que en SQL: {@code lower(btrim(name))}. */
    private static String normalizeCellIdentifier(String name) {
        if (name == null) {
            return "";
        }
        return name.trim().toLowerCase(Locale.ROOT);
    }

    /** Tareas que se eliminarían al borrar la célula (mismo alcance que {@link #deleteCell(long)}). */
    public int countTasksForCellDelete(long cellId) {
        ensureCell(cellId);
        return taskJdbcRepository.countByCellId(cellId);
    }

    /** Tareas vinculadas a un repositorio de célula antes de {@link #deleteRepo(long, long)}. */
    public int countTasksForRepoDelete(long cellId, long repoId) {
        ensureCell(cellId);
        CellRepoEntity existing =
                cellRepoRepository
                        .findById(repoId)
                        .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Repositorio no encontrado"));
        if (!Objects.equals(existing.cellId(), cellId)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "El repositorio no pertenece a la celda");
        }
        return taskJdbcRepository.countByCellRepoId(repoId);
    }

    @Transactional
    public void deleteCell(long id) {
        ensureCell(id);
        for (CellRepoEntity repo : cellRepoRepository.findByCellId(id)) {
            clearIndexedArtifactsForRepo(repo);
        }
        taskJdbcRepository.deleteByCellId(id);
        if (!cellRepository.delete(id)) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Celda no encontrada");
        }
    }

    /**
     * Quita embeddings pgvector/Pinecone y objetos de soporte en S3 asociados al namespace del repo
     * (misma lógica que {@link #deleteRepo(long, long)} antes de borrar la fila).
     */
    private void clearIndexedArtifactsForRepo(CellRepoEntity existing) {
        if (existing.linkedWithoutReindex()) {
            return;
        }
        if (existing.vectorNamespace() == null || existing.vectorNamespace().isBlank()) {
            return;
        }
        String ns = existing.vectorNamespace().trim();
        vectorIngestService.clearNamespace(ns);
        SupportS3Service s3 = supportS3Service.getIfAvailable();
        if (s3 != null) {
            String pfx = supportS3PathBuilder.cellRepoSupportPrefix(existing);
            if (pfx != null && !pfx.isBlank()) {
                s3.deleteObjectsWithPrefix(pfx);
            }
        }
    }

    public List<CellRepoResponse> listRepos(long cellId) {
        ensureCell(cellId);
        return cellRepoRepository.findByCellId(cellId).stream().map(this::toRepoDto).collect(Collectors.toList());
    }

    public CellRepoResponse createRepo(long cellId, CellRepoRequest req) {
        return createRepo(cellId, req, null);
    }

    /**
     * Crea repo en la célula y opcionalmente emite progreso de indexación (mismo contrato NDJSON que
     * {@code /vector/ingest/stream}: START, FILE, PROGRESS, DONE; al final {@link IngestProgressDto#cellRepoReady}).
     */
    public CellRepoResponse createRepo(long cellId, CellRepoRequest req, Consumer<IngestProgressDto> onProgress) {
        ensureCell(cellId);
        validateMode(req);
        if (req.connectionMode() == GitConnectionMode.HTTPS_AUTH
                && (req.credentialPlain() == null || req.credentialPlain().isBlank())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Credencial requerida para HTTPS con autenticación");
        }
        String modeStr = req.connectionMode().name();
        String repoKey =
                RepositoryUrlNormalizer.normalizeRepositoryKey(req.repositoryUrl(), req.localPath(), modeStr);
        if (repoKey.isBlank()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "URL o ruta local requerida");
        }
        if (cellRepoRepository.existsByCellIdAndRepositoryKeyNorm(cellId, repoKey)) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Este repositorio ya está en esta célula");
        }

        Optional<CellRepoEntity> orphanSameKey = cellRepoRepository.findOrphanByRepositoryKey(repoKey);
        if (orphanSameKey.isPresent()) {
            CellRepoEntity o = orphanSameKey.get();
            if (!cellRepoRepository.updateCellIdWhereNull(o.id(), cellId)) {
                throw new ResponseStatusException(
                        HttpStatus.CONFLICT, "No se pudo enlazar el repositorio pendiente a la célula");
            }
            CellRepoResponse dto = cellRepoRepository.findById(o.id()).map(this::toRepoDto).orElseThrow();
            if (onProgress != null) {
                onProgress.accept(IngestProgressDto.start(0));
                onProgress.accept(IngestProgressDto.cellRepoReady(dto));
            }
            return dto;
        }

        Optional<CellRepoEntity> existingAnywhere = cellRepoRepository.findFirstByRepositoryKey(repoKey);
        if (existingAnywhere.isPresent()) {
            CellRepoEntity src = existingAnywhere.get();
            String displayName =
                    req.displayName() != null && !req.displayName().isBlank()
                            ? req.displayName().trim()
                            : src.displayName();
            String tagsCsv =
                    req.tagsCsv() != null && !req.tagsCsv().isBlank()
                            ? req.tagsCsv().trim()
                            : src.tagsCsv();
            long linkId =
                    cellRepoRepository.insertLinkedFromCanonical(
                            cellId, src, tagsCsv, repoKey, displayName);
            CellRepoResponse dto = cellRepoRepository.findById(linkId).map(this::toRepoDto).orElseThrow();
            if (onProgress != null) {
                onProgress.accept(IngestProgressDto.start(0));
                onProgress.accept(IngestProgressDto.cellRepoReady(dto));
            }
            return dto;
        }

        String displayName =
                req.displayName() != null && !req.displayName().isBlank()
                        ? req.displayName().trim()
                        : GitRepositoryService.slugFromGitUrl(
                                req.connectionMode() == GitConnectionMode.LOCAL
                                        ? (req.localPath() != null ? req.localPath() : "")
                                        : req.repositoryUrl());
        if (displayName.isBlank()) {
            displayName = "repo";
        }
        String vectorNs;
        if (req.vectorNamespace() != null && !req.vectorNamespace().isBlank()) {
            vectorNs = RepositoryUrlNormalizer.clampNamespace(req.vectorNamespace().trim(), NS_MAX);
        } else {
            vectorNs =
                    RepositoryUrlNormalizer.clampNamespace(
                            displayName + "__" + UUID.randomUUID().toString().replace("-", ""), NS_MAX);
        }

        String enc = encryptCredential(req);
        String repoUrlToStore = req.repositoryUrl().trim();
        String localPathToStore = blankToNull(req.localPath());

        Object lock = ingestLocks.computeIfAbsent(repoKey, k -> new Object());
        synchronized (lock) {
            try {
                long id =
                        cellRepoRepository.insert(
                                cellId,
                                displayName,
                                repoUrlToStore,
                                modeStr,
                                blankToNull(req.gitUsername()),
                                enc,
                                localPathToStore,
                                blankToNull(req.tagsCsv()),
                                vectorNs,
                                repoKey);
                VectorIngestResponse ingestResult = null;
                try {
                    GitConnectRequest g = buildGitConnectFromRequest(req);
                    g.setVectorNamespace(vectorNs);
                    if (onProgress != null) {
                        onProgress.accept(
                                IngestProgressDto.detail("Clonando y conectando al repositorio (puede tardar varios minutos)…"));
                    }
                    gitRepositoryService.connect(g);
                    if (onProgress != null) {
                        onProgress.accept(IngestProgressDto.detail("Vectorizando archivos…"));
                    }
                    ingestResult = vectorIngestService.ingestAll(onProgress, vectorNs);
                    String skippedJson =
                            objectMapper.writeValueAsString(
                                    ingestResult.getSkipped() != null ? ingestResult.getSkipped() : List.of());
                    cellRepoRepository.updateLastIngest(
                            id,
                            Instant.now(),
                            ingestResult.getFilesProcessed(),
                            ingestResult.getChunksIndexed(),
                            skippedJson);
                } catch (ResponseStatusException e) {
                    cellRepoRepository.delete(id);
                    throw e;
                } catch (Exception e) {
                    cellRepoRepository.delete(id);
                    throw new ResponseStatusException(
                            HttpStatus.BAD_REQUEST, "No se pudo clonar o indexar: " + e.getMessage(), e);
                } finally {
                    gitRepositoryService.disconnectCleanup();
                }
                CellRepoResponse result = cellRepoRepository.findById(id).map(this::toRepoDto).orElseThrow();
                if (onProgress != null) {
                    onProgress.accept(IngestProgressDto.cellRepoReady(result, ingestResult));
                }
                return result;
            } finally {
                ingestLocks.remove(repoKey, lock);
            }
        }
    }

    /**
     * Indexa el repositorio sin célula; la fila queda con {@code cell_id} null hasta “Guardar” en el editor
     * ({@link #assignOrphansToCell(long, List)}).
     */
    public CellRepoResponse indexRepoOrphan(CellRepoRequest req, Consumer<IngestProgressDto> onProgress) {
        validateMode(req);
        if (req.connectionMode() == GitConnectionMode.HTTPS_AUTH
                && (req.credentialPlain() == null || req.credentialPlain().isBlank())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Credencial requerida para HTTPS con autenticación");
        }
        String modeStr = req.connectionMode().name();
        String repoKey =
                RepositoryUrlNormalizer.normalizeRepositoryKey(req.repositoryUrl(), req.localPath(), modeStr);
        if (repoKey.isBlank()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "URL o ruta local requerida");
        }

        Optional<CellRepoEntity> orphan = cellRepoRepository.findOrphanByRepositoryKey(repoKey);
        if (orphan.isPresent()) {
            CellRepoResponse dto = cellRepoRepository.findById(orphan.get().id()).map(this::toRepoDto).orElseThrow();
            if (onProgress != null) {
                onProgress.accept(IngestProgressDto.start(0));
                onProgress.accept(IngestProgressDto.cellRepoReady(dto));
            }
            return dto;
        }

        Optional<CellRepoEntity> existingAnywhere = cellRepoRepository.findFirstByRepositoryKey(repoKey);
        if (existingAnywhere.isPresent() && existingAnywhere.get().cellId() != null) {
            CellRepoEntity src = existingAnywhere.get();
            String displayName =
                    req.displayName() != null && !req.displayName().isBlank()
                            ? req.displayName().trim()
                            : src.displayName();
            String tagsCsv =
                    req.tagsCsv() != null && !req.tagsCsv().isBlank()
                            ? req.tagsCsv().trim()
                            : src.tagsCsv();
            long linkId =
                    cellRepoRepository.insertLinkedFromCanonicalOrphan(src, tagsCsv, repoKey, displayName);
            CellRepoResponse dto = cellRepoRepository.findById(linkId).map(this::toRepoDto).orElseThrow();
            if (onProgress != null) {
                onProgress.accept(IngestProgressDto.start(0));
                onProgress.accept(IngestProgressDto.cellRepoReady(dto));
            }
            return dto;
        }

        String displayName =
                req.displayName() != null && !req.displayName().isBlank()
                        ? req.displayName().trim()
                        : GitRepositoryService.slugFromGitUrl(
                                req.connectionMode() == GitConnectionMode.LOCAL
                                        ? (req.localPath() != null ? req.localPath() : "")
                                        : req.repositoryUrl());
        if (displayName.isBlank()) {
            displayName = "repo";
        }
        String vectorNs;
        if (req.vectorNamespace() != null && !req.vectorNamespace().isBlank()) {
            vectorNs = RepositoryUrlNormalizer.clampNamespace(req.vectorNamespace().trim(), NS_MAX);
        } else {
            vectorNs =
                    RepositoryUrlNormalizer.clampNamespace(
                            displayName + "__" + UUID.randomUUID().toString().replace("-", ""), NS_MAX);
        }

        String enc = encryptCredential(req);
        String repoUrlToStore = req.repositoryUrl().trim();
        String localPathToStore = blankToNull(req.localPath());

        Object lock = ingestLocks.computeIfAbsent(repoKey, k -> new Object());
        synchronized (lock) {
            try {
                long id =
                        cellRepoRepository.insert(
                                null,
                                displayName,
                                repoUrlToStore,
                                modeStr,
                                blankToNull(req.gitUsername()),
                                enc,
                                localPathToStore,
                                blankToNull(req.tagsCsv()),
                                vectorNs,
                                repoKey);
                VectorIngestResponse ingestResult = null;
                try {
                    GitConnectRequest g = buildGitConnectFromRequest(req);
                    g.setVectorNamespace(vectorNs);
                    if (onProgress != null) {
                        onProgress.accept(
                                IngestProgressDto.detail("Clonando y conectando al repositorio (puede tardar varios minutos)…"));
                    }
                    gitRepositoryService.connect(g);
                    if (onProgress != null) {
                        onProgress.accept(IngestProgressDto.detail("Vectorizando archivos…"));
                    }
                    ingestResult = vectorIngestService.ingestAll(onProgress, vectorNs);
                    String skippedJson =
                            objectMapper.writeValueAsString(
                                    ingestResult.getSkipped() != null ? ingestResult.getSkipped() : List.of());
                    cellRepoRepository.updateLastIngest(
                            id,
                            Instant.now(),
                            ingestResult.getFilesProcessed(),
                            ingestResult.getChunksIndexed(),
                            skippedJson);
                } catch (ResponseStatusException e) {
                    cellRepoRepository.delete(id);
                    throw e;
                } catch (Exception e) {
                    cellRepoRepository.delete(id);
                    throw new ResponseStatusException(
                            HttpStatus.BAD_REQUEST, "No se pudo clonar o indexar: " + e.getMessage(), e);
                } finally {
                    gitRepositoryService.disconnectCleanup();
                }
                CellRepoResponse result = cellRepoRepository.findById(id).map(this::toRepoDto).orElseThrow();
                if (onProgress != null) {
                    onProgress.accept(IngestProgressDto.cellRepoReady(result, ingestResult));
                }
                return result;
            } finally {
                ingestLocks.remove(repoKey, lock);
            }
        }
    }

    public List<CellRepoResponse> assignOrphansToCell(long cellId, List<Long> repoIds) {
        ensureCell(cellId);
        if (repoIds == null || repoIds.isEmpty()) {
            return List.of();
        }
        List<CellRepoResponse> out = new ArrayList<>();
        for (long rid : repoIds) {
            CellRepoEntity e =
                    cellRepoRepository
                            .findById(rid)
                            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Repositorio no encontrado"));
            if (e.cellId() != null) {
                if (Objects.equals(e.cellId(), cellId)) {
                    out.add(toRepoDto(e));
                    continue;
                }
                throw new ResponseStatusException(HttpStatus.CONFLICT, "El repositorio ya está asignado a otra célula");
            }
            String key =
                    RepositoryUrlNormalizer.normalizeRepositoryKey(
                            e.repositoryUrl(), e.localPath(), e.connectionMode());
            if (cellRepoRepository.existsByCellIdAndRepositoryKeyNorm(cellId, key)) {
                throw new ResponseStatusException(HttpStatus.CONFLICT, "Esta URL ya está en esta célula");
            }
            if (!cellRepoRepository.updateCellIdWhereNull(rid, cellId)) {
                throw new ResponseStatusException(
                        HttpStatus.CONFLICT, "No se pudo asignar el repositorio (¿estado cambiado?)");
            }
            out.add(cellRepoRepository.findById(rid).map(this::toRepoDto).orElseThrow());
        }
        return out;
    }

    public void deleteOrphanRepo(long repoId) {
        CellRepoEntity e =
                cellRepoRepository
                        .findById(repoId)
                        .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Repositorio no encontrado"));
        if (e.cellId() != null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Solo se pueden descartar repositorios pendientes");
        }
        if (!e.linkedWithoutReindex() && e.vectorNamespace() != null && !e.vectorNamespace().isBlank()) {
            vectorIngestService.clearNamespace(e.vectorNamespace());
        }
        cellRepoRepository.delete(repoId);
    }

    private GitConnectRequest buildGitConnectFromRequest(CellRepoRequest req) {
        GitConnectRequest g = new GitConnectRequest();
        g.setMode(req.connectionMode());
        g.setRepositoryUrl(req.repositoryUrl().trim());
        g.setLocalPath(blankToNull(req.localPath()));
        g.setUsername(blankToNull(req.gitUsername()));
        if (req.connectionMode() == GitConnectionMode.HTTPS_AUTH) {
            String t = req.credentialPlain();
            if (t == null || t.isBlank()) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Credencial requerida");
            }
            g.setToken(t.trim());
        }
        return g;
    }

    public CellRepoResponse updateRepo(long cellId, long repoId, CellRepoRequest req) {
        ensureCell(cellId);
        CellRepoEntity existing = cellRepoRepository.findById(repoId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Repositorio no encontrado"));
        if (!Objects.equals(existing.cellId(), cellId)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "El repositorio no pertenece a la celda");
        }
        validateMode(req);
        String enc = existing.credentialEncrypted();
        if (req.credentialPlain() != null && !req.credentialPlain().isBlank()) {
            enc = credentialCryptoService.encrypt(req.credentialPlain());
        } else if (req.connectionMode() == GitConnectionMode.HTTPS_AUTH && (enc == null || enc.isBlank())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Credencial requerida para HTTPS con autenticación");
        }
        String displayName =
                req.displayName() != null && !req.displayName().isBlank()
                        ? req.displayName().trim()
                        : existing.displayName();
        String vectorNs =
                req.vectorNamespace() != null && !req.vectorNamespace().isBlank()
                        ? req.vectorNamespace().trim()
                        : existing.vectorNamespace();
        String newKey =
                RepositoryUrlNormalizer.normalizeRepositoryKey(
                        req.repositoryUrl(), req.localPath(), req.connectionMode().name());
        if (newKey.isBlank()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "URL o ruta local requerida");
        }
        if (cellRepoRepository.existsOtherInCellWithRepositoryKeyNorm(cellId, repoId, newKey)) {
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT, "Esta URL de repositorio ya está en esta célula");
        }
        cellRepoRepository.update(
                repoId,
                displayName,
                req.repositoryUrl().trim(),
                req.connectionMode().name(),
                blankToNull(req.gitUsername()),
                enc,
                blankToNull(req.localPath()),
                blankToNull(req.tagsCsv()),
                vectorNs,
                newKey);
        return cellRepoRepository.findById(repoId).map(this::toRepoDto).orElseThrow();
    }

    public void deleteRepo(long cellId, long repoId) {
        ensureCell(cellId);
        CellRepoEntity existing = cellRepoRepository.findById(repoId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Repositorio no encontrado"));
        if (!Objects.equals(existing.cellId(), cellId)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "El repositorio no pertenece a la celda");
        }
        clearIndexedArtifactsForRepo(existing);
        cellRepoRepository.delete(repoId);
    }

    /** Árbol de archivos del repo (clon efímero) para el panel de administración. */
    public FolderStructureDto getAdminRepoFolderStructure(long cellId, long repoId) {
        ensureCell(cellId);
        CellRepoEntity e = cellRepoRepository.findById(repoId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Repositorio no encontrado"));
        if (!Objects.equals(e.cellId(), cellId)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "El repositorio no pertenece a la celda");
        }
        GitConnectRequest g = buildGitConnectFromEntity(e);
        try {
            return gitRepositoryService.loadEphemeralFolderStructure(g);
        } catch (IllegalStateException ex) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, ex.getMessage(), ex);
        }
    }

    /** Lectura de un archivo del repo para visualización (solo lectura) en administración. */
    public FileContentResponse getAdminRepoFileContent(long cellId, long repoId, String path) {
        if (path == null || path.isBlank()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Parámetro path requerido");
        }
        ensureCell(cellId);
        CellRepoEntity e = cellRepoRepository.findById(repoId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Repositorio no encontrado"));
        if (!Objects.equals(e.cellId(), cellId)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "El repositorio no pertenece a la celda");
        }
        GitConnectRequest g = buildGitConnectFromEntity(e);
        try {
            return gitRepositoryService.loadEphemeralFileContent(g, path);
        } catch (IllegalStateException ex) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, ex.getMessage(), ex);
        }
    }

    /** Árbol para un repo huérfano (alta de célula, aún sin “Guardar”). */
    public FolderStructureDto getPendingRepoFolderStructure(long repoId) {
        CellRepoEntity e = cellRepoRepository.findById(repoId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Repositorio no encontrado"));
        if (e.cellId() != null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "El repositorio ya está asignado a una célula");
        }
        GitConnectRequest g = buildGitConnectFromEntity(e);
        try {
            return gitRepositoryService.loadEphemeralFolderStructure(g);
        } catch (IllegalStateException ex) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, ex.getMessage(), ex);
        }
    }

    public FileContentResponse getPendingRepoFileContent(long repoId, String path) {
        if (path == null || path.isBlank()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Parámetro path requerido");
        }
        CellRepoEntity e = cellRepoRepository.findById(repoId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Repositorio no encontrado"));
        if (e.cellId() != null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "El repositorio ya está asignado a una célula");
        }
        GitConnectRequest g = buildGitConnectFromEntity(e);
        try {
            return gitRepositoryService.loadEphemeralFileContent(g, path);
        } catch (IllegalStateException ex) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, ex.getMessage(), ex);
        }
    }

    private GitConnectRequest buildGitConnectFromEntity(CellRepoEntity e) {
        GitConnectionMode mode;
        try {
            mode = GitConnectionMode.valueOf(e.connectionMode());
        } catch (Exception ex) {
            mode = GitConnectionMode.HTTPS_PUBLIC;
        }
        GitConnectRequest g = new GitConnectRequest();
        g.setMode(mode);
        switch (mode) {
            case LOCAL -> {
                if (e.localPath() == null || e.localPath().isBlank()) {
                    throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Ruta local no configurada");
                }
                g.setLocalPath(e.localPath());
                g.setRepositoryUrl(e.repositoryUrl() != null ? e.repositoryUrl() : "");
            }
            case HTTPS_PUBLIC -> g.setRepositoryUrl(e.repositoryUrl());
            case HTTPS_AUTH -> {
                g.setRepositoryUrl(e.repositoryUrl());
                String user = e.gitUsername() != null && !e.gitUsername().isBlank() ? e.gitUsername().trim() : "git";
                g.setUsername(user);
                if (e.credentialEncrypted() == null || e.credentialEncrypted().isBlank()) {
                    throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Credencial no disponible para este repositorio");
                }
                g.setToken(credentialCryptoService.decrypt(e.credentialEncrypted()));
            }
        }
        if (e.vectorNamespace() != null && !e.vectorNamespace().isBlank()) {
            g.setVectorNamespace(e.vectorNamespace());
        }
        return g;
    }

    private void ensureCell(long cellId) {
        cellRepository.findById(cellId).orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Celda no encontrada"));
    }

    /** Comprueba que el repositorio de celda pertenece a la célula indicada. */
    public void assertRepoBelongsToCell(long cellId, long repoId) {
        ensureCell(cellId);
        CellRepoEntity e = cellRepoRepository.findById(repoId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Repositorio no encontrado"));
        if (!Objects.equals(e.cellId(), cellId)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "El repositorio no pertenece a la celda");
        }
    }

    /** Repo indexado pero aún sin célula (flujo “Nueva célula”). */
    public void assertPendingOrphanRepo(long repoId) {
        CellRepoEntity e = cellRepoRepository.findById(repoId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Repositorio no encontrado"));
        if (e.cellId() != null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "El repositorio ya está asignado a una célula");
        }
    }

    private void validateMode(CellRepoRequest req) {
        if (req.connectionMode() == GitConnectionMode.LOCAL) {
            if (req.localPath() == null || req.localPath().isBlank()) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Ruta local requerida para modo LOCAL");
            }
        }
        if (req.connectionMode() == GitConnectionMode.HTTPS_AUTH) {
            if (req.credentialPlain() == null || req.credentialPlain().isBlank()) {
                // puede venir vacío en PUT si ya hay credencial
            }
        }
    }

    private String encryptCredential(CellRepoRequest req) {
        if (req.connectionMode() != GitConnectionMode.HTTPS_AUTH) {
            return null;
        }
        if (req.credentialPlain() == null || req.credentialPlain().isBlank()) {
            return null;
        }
        return credentialCryptoService.encrypt(req.credentialPlain());
    }

    private static String blankToNull(String s) {
        if (s == null || s.isBlank()) {
            return null;
        }
        return s.trim();
    }

    private CellResponse toCellDto(CellEntity e) {
        return new CellResponse(e.id(), e.name(), e.description(), e.createdAt(), e.createdBy());
    }

    private CellRepoResponse toRepoDto(CellRepoEntity e) {
        GitConnectionMode mode;
        try {
            mode = GitConnectionMode.valueOf(e.connectionMode());
        } catch (Exception ex) {
            mode = GitConnectionMode.HTTPS_PUBLIC;
        }
        boolean hasCred = e.credentialEncrypted() != null && !e.credentialEncrypted().isBlank();
        List<String> skipped = List.of();
        if (e.lastIngestSkippedJson() != null && !e.lastIngestSkippedJson().isBlank()) {
            try {
                skipped = objectMapper.readValue(e.lastIngestSkippedJson(), new TypeReference<>() {});
            } catch (JsonProcessingException ignored) {
            }
        }
        return new CellRepoResponse(
                e.id(),
                e.cellId(),
                e.displayName(),
                e.repositoryUrl(),
                mode,
                e.gitUsername(),
                hasCred,
                e.localPath(),
                e.tagsCsv(),
                e.vectorNamespace(),
                e.active(),
                e.createdAt(),
                e.updatedAt(),
                e.lastIngestAt(),
                e.lastIngestFiles(),
                e.lastIngestChunks(),
                skipped,
                e.linkedWithoutReindex());
    }
}
