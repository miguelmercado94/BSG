package com.bsg.docviz.support;

import com.bsg.docviz.config.DocvizSupportProperties;
import com.bsg.docviz.dto.S3FileUrlItem;
import com.bsg.docviz.dto.SupportMarkdownUploadResponse;
import com.bsg.docviz.dto.VectorIngestResponse;
import com.bsg.docviz.repository.CellRepoEntity;
import com.bsg.docviz.repository.CellRepoJdbcRepository;
import com.bsg.docviz.util.SourceTextExtractor;
import com.bsg.docviz.vector.VectorIngestService;
import com.bsg.docviz.vector.VectorStore;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;

import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.List;
import java.util.Locale;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@ConditionalOnProperty(name = "docviz.support.enabled", havingValue = "true")
public class SupportMarkdownService {

    private final SupportS3Service supportS3Service;
    private final VectorIngestService vectorIngestService;
    private final VectorStore vectorStore;
    private final DocvizSupportProperties supportProperties;
    private final CellRepoJdbcRepository cellRepoJdbcRepository;
    private final SupportS3PathBuilder supportS3PathBuilder;

    public SupportMarkdownService(
            SupportS3Service supportS3Service,
            VectorIngestService vectorIngestService,
            VectorStore vectorStore,
            DocvizSupportProperties supportProperties,
            CellRepoJdbcRepository cellRepoJdbcRepository,
            SupportS3PathBuilder supportS3PathBuilder
    ) {
        this.supportS3Service = supportS3Service;
        this.vectorIngestService = vectorIngestService;
        this.vectorStore = vectorStore;
        this.supportProperties = supportProperties;
        this.cellRepoJdbcRepository = cellRepoJdbcRepository;
        this.supportS3PathBuilder = supportS3PathBuilder;
    }

    /**
     * Lista objetos .md en S3 del repo; el front descarga con la URL presignada (sin pasar el cuerpo por la API).
     */
    public List<S3FileUrlItem> listObjectsForCellRepo(long cellRepoId) {
        CellRepoEntity repo = cellRepoJdbcRepository.findById(cellRepoId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Repositorio de celda no encontrado"));
        if (repo.vectorNamespace() == null || repo.vectorNamespace().isBlank()) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Configure el namespace vectorial en el repositorio (copiado de GET /session/vector-namespace tras conectar)");
        }
        String prefix = supportS3PathBuilder.cellRepoSupportPrefix(repo);
        if (prefix.isBlank()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Prefijo S3 de soporte no resuelto para el repositorio");
        }
        Duration ttl = Duration.ofSeconds(supportProperties.getPresignedUrlTtlSeconds());
        return supportS3Service.listObjectKeys(prefix).stream()
                .map(k -> toUrlItem(prefix, k, ttl))
                .collect(Collectors.toList());
    }

    private S3FileUrlItem toUrlItem(String prefix, String key, Duration ttl) {
        String rel = key.length() > prefix.length() ? key.substring(prefix.length()) : key;
        String fileName = rel != null && !rel.isBlank() ? rel.replace('\\', '/') : key;
        String bucket = supportS3Service.supportBucket();
        String url = supportS3Service.presignGetUrl(key, ttl);
        return new S3FileUrlItem(bucket, key, fileName, url);
    }

    /**
     * Sube un .md de soporte para un repositorio de célula (admin), indexa en el namespace del repo sin sesión Git.
     * Ruta S3 según {@link DocvizSupportProperties#getSupportRepoPrefixTemplate()}.
     */
    public SupportMarkdownUploadResponse uploadAndIndexForCellRepo(
            long cellRepoId, MultipartFile file, String huCode, String huTitle) {
        if (huCode == null || huCode.isBlank()) {
            throw new IllegalArgumentException("Código de HU obligatorio");
        }
        if (huTitle == null || huTitle.isBlank()) {
            throw new IllegalArgumentException("Título de HU obligatorio");
        }
        CellRepoEntity repo = cellRepoJdbcRepository.findById(cellRepoId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Repositorio de celda no encontrado"));
        if (repo.vectorNamespace() == null || repo.vectorNamespace().isBlank()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Namespace vectorial no configurado en el repositorio");
        }
        if (file == null || file.isEmpty()) {
            throw new IllegalArgumentException("Archivo vacío");
        }
        if (file.getSize() > supportProperties.getMaxUploadBytes()) {
            throw new IllegalArgumentException("El archivo supera el tamaño máximo permitido");
        }
        String original = file.getOriginalFilename() != null ? file.getOriginalFilename() : "soporte.md";
        if (!original.toLowerCase(Locale.ROOT).endsWith(".md")) {
            throw new IllegalArgumentException("Solo se admiten archivos .md");
        }
        byte[] bytes;
        try {
            bytes = file.getBytes();
        } catch (java.io.IOException e) {
            throw new IllegalStateException("No se pudo leer el archivo: " + e.getMessage(), e);
        }
        String ns = repo.vectorNamespace().trim();
        String prefix = supportS3PathBuilder.cellRepoSupportPrefix(repo);
        String safe = safeFileName(original);
        String objectKey = prefix + safe;
        supportS3Service.putObject(objectKey, bytes, "text/markdown; charset=utf-8");
        String text = SourceTextExtractor.extractText(safe, bytes);
        if (text == null || text.isBlank()) {
            supportS3Service.deleteObject(objectKey);
            throw new IllegalArgumentException("El Markdown no contiene texto indexable");
        }
        String source = SupportMarkdownConstants.sourceForObjectKey(objectKey);
        VectorIngestResponse r = vectorIngestService.ingestSupportPlainTextForNamespace(ns, source, text);
        SupportMarkdownUploadResponse out = new SupportMarkdownUploadResponse();
        out.setBucket(supportS3Service.supportBucket());
        out.setObjectKey(objectKey);
        out.setFileName(objectKey.substring(prefix.length()));
        out.setVectorSource(source);
        out.setNamespace(r.getNamespace());
        out.setChunksIndexed(r.getChunksIndexed());
        return out;
    }

    /** Elimina objeto en S3 y vectores asociados (admin). {@code fileName} es la ruta relativa al prefijo del repo. */
    public void deleteForCellRepo(long cellRepoId, String fileName) {
        CellRepoEntity repo = cellRepoJdbcRepository.findById(cellRepoId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Repositorio de celda no encontrado"));
        if (repo.vectorNamespace() == null || repo.vectorNamespace().isBlank()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Namespace vectorial no configurado");
        }
        String prefix = supportS3PathBuilder.cellRepoSupportPrefix(repo);
        String objectKey = resolveStorageFileName(prefix, fileName);
        String source = SupportMarkdownConstants.sourceForObjectKey(objectKey);
        vectorStore.deleteBySource(repo.vectorNamespace().trim(), source);
        supportS3Service.deleteObject(objectKey);
    }

    /** Guarda nuevo contenido, reindexa y actualiza S3. */
    public SupportMarkdownUploadResponse updateForCellRepo(long cellRepoId, String fileName, String newText) {
        CellRepoEntity repo = cellRepoJdbcRepository.findById(cellRepoId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Repositorio de celda no encontrado"));
        if (repo.vectorNamespace() == null || repo.vectorNamespace().isBlank()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Namespace vectorial no configurado");
        }
        String prefix = supportS3PathBuilder.cellRepoSupportPrefix(repo);
        String objectKey = resolveStorageFileName(prefix, fileName);
        if (newText == null || newText.isBlank()) {
            throw new IllegalArgumentException("El texto no puede estar vacío");
        }
        String ns = repo.vectorNamespace().trim();
        String source = SupportMarkdownConstants.sourceForObjectKey(objectKey);
        vectorStore.deleteBySource(ns, source);
        byte[] bytes = newText.getBytes(StandardCharsets.UTF_8);
        supportS3Service.putObject(objectKey, bytes, "text/markdown; charset=utf-8");
        String text = SourceTextExtractor.extractText("soporte.md", bytes);
        if (text == null || text.isBlank()) {
            throw new IllegalArgumentException("El Markdown no contiene texto indexable");
        }
        VectorIngestResponse r = vectorIngestService.ingestSupportPlainTextForNamespace(ns, source, text);
        SupportMarkdownUploadResponse out = new SupportMarkdownUploadResponse();
        out.setBucket(supportS3Service.supportBucket());
        out.setObjectKey(objectKey);
        out.setFileName(objectKey.substring(prefix.length()));
        out.setVectorSource(source);
        out.setNamespace(r.getNamespace());
        out.setChunksIndexed(r.getChunksIndexed());
        return out;
    }

    private static String slugSegment(String raw, String fallback) {
        if (raw == null || raw.isBlank()) {
            return fallback;
        }
        String t = raw.trim().replaceAll("[^a-zA-Z0-9._-]+", "_");
        return t.isBlank() ? fallback : t;
    }

    public SupportMarkdownUploadResponse uploadAndIndex(MultipartFile file) {
        if (file == null || file.isEmpty()) {
            throw new IllegalArgumentException("Archivo vacío");
        }
        if (file.getSize() > supportProperties.getMaxUploadBytes()) {
            throw new IllegalArgumentException("El archivo supera el tamaño máximo permitido");
        }
        String original = file.getOriginalFilename() != null ? file.getOriginalFilename() : "soporte.md";
        if (!original.toLowerCase(Locale.ROOT).endsWith(".md")) {
            throw new IllegalArgumentException("Solo se admiten archivos .md");
        }
        byte[] bytes;
        try {
            bytes = file.getBytes();
        } catch (java.io.IOException e) {
            throw new IllegalStateException("No se pudo leer el archivo: " + e.getMessage(), e);
        }
        String safe = safeFileName(original);
        String prefix = keyPrefix();
        String objectKey = buildObjectKey(safe);
        supportS3Service.putObject(objectKey, bytes, "text/markdown; charset=utf-8");
        String text = SourceTextExtractor.extractText("soporte.md", bytes);
        if (text == null || text.isBlank()) {
            supportS3Service.deleteObject(objectKey);
            throw new IllegalArgumentException("El Markdown no contiene texto indexable");
        }
        String source = SupportMarkdownConstants.sourceForObjectKey(objectKey);
        VectorIngestResponse r = vectorIngestService.ingestSupportPlainText(source, text);
        SupportMarkdownUploadResponse out = new SupportMarkdownUploadResponse();
        out.setBucket(supportS3Service.supportBucket());
        out.setObjectKey(objectKey);
        out.setFileName(objectKey.substring(prefix.length()));
        out.setVectorSource(source);
        out.setNamespace(r.getNamespace());
        out.setChunksIndexed(r.getChunksIndexed());
        return out;
    }

    /** Borra por nombre relativo al prefijo de sesión (mismo valor que {@link SupportMarkdownUploadResponse#getFileName()}). */
    public void deleteIndexed(String fileName) {
        String prefix = keyPrefix();
        String objectKey = resolveStorageFileName(prefix, fileName);
        validateSessionKey(objectKey);
        String source = SupportMarkdownConstants.sourceForObjectKey(objectKey);
        String ns = vectorIngestService.currentNamespace();
        vectorStore.deleteBySource(ns, source);
        supportS3Service.deleteObject(objectKey);
    }

    private void validateSessionKey(String objectKey) {
        String prefix = keyPrefix();
        if (objectKey == null || objectKey.isBlank() || !objectKey.startsWith(prefix)) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Clave de objeto no válida para esta sesión");
        }
    }

    private String keyPrefix() {
        return supportS3PathBuilder.sessionSupportPrefix(vectorIngestService.currentNamespace());
    }

    private String buildObjectKey(String safeName) {
        return keyPrefix() + UUID.randomUUID() + "_" + safeName;
    }

    private static String safeFileName(String original) {
        String s = original == null || original.isBlank() ? "soporte.md" : original.trim();
        s = s.replaceAll("[\\\\/]+", "_");
        if (!s.toLowerCase(Locale.ROOT).endsWith(".md")) {
            s = s + ".md";
        }
        if (s.length() > 180) {
            s = s.substring(0, 176) + ".md";
        }
        return s;
    }

    private static String resolveStorageFileName(String prefix, String fileName) {
        if (fileName == null || fileName.isBlank()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "fileName obligatorio");
        }
        String fn = fileName.trim().replace('\\', '/');
        if (fn.contains("..") || fn.startsWith("/")) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "fileName inválido");
        }
        return prefix + fn;
    }
}
