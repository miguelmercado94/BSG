package com.bsg.docviz.service;



import com.bsg.docviz.config.DocvizSupportProperties;

import com.bsg.docviz.config.DocvizWorkspaceS3Properties;

import com.bsg.docviz.domain.workspace.WorkspaceS3KeyBuilder;

import com.bsg.docviz.dto.S3FileUrlItem;

import com.bsg.docviz.dto.VectorIngestResponse;

import com.bsg.docviz.support.SupportS3Service;

import com.bsg.docviz.vector.VectorIngestService;

import org.slf4j.Logger;

import org.slf4j.LoggerFactory;

import jakarta.annotation.PostConstruct;

import org.springframework.beans.factory.ObjectProvider;

import org.springframework.beans.factory.annotation.Value;

import org.springframework.http.HttpStatus;

import org.springframework.stereotype.Service;

import org.springframework.web.server.ResponseStatusException;



import java.nio.charset.StandardCharsets;

import java.time.Duration;

import java.util.ArrayList;

import java.util.List;



/**

 * Borradores en bucket {@code borradores}; copias aceptadas en {@code workarea}. Endpoint y credenciales comunes en

 * {@code docviz.support.s3-endpoint}.

 */

@Service

public class WorkAreaS3ArtifactService {



    private static final Logger log = LoggerFactory.getLogger(WorkAreaS3ArtifactService.class);



    private final ObjectProvider<SupportS3Service> supportS3;

    private final WorkspaceS3KeyBuilder keyBuilder;

    private final VectorIngestService vectorIngestService;

    private final DocvizSupportProperties supportProperties;

    private final DocvizWorkspaceS3Properties workspaceProperties;

    private final boolean workspaceS3Enabled;



    public WorkAreaS3ArtifactService(

            ObjectProvider<SupportS3Service> supportS3,

            WorkspaceS3KeyBuilder keyBuilder,

            VectorIngestService vectorIngestService,

            DocvizSupportProperties supportProperties,

            DocvizWorkspaceS3Properties workspaceProperties,

            @Value("${docviz.workspace-s3.enabled:false}") boolean workspaceS3Enabled) {

        this.supportS3 = supportS3;

        this.keyBuilder = keyBuilder;

        this.vectorIngestService = vectorIngestService;

        this.supportProperties = supportProperties;

        this.workspaceProperties = workspaceProperties;

        this.workspaceS3Enabled = workspaceS3Enabled;

    }



    @PostConstruct

    void logS3Availability() {

        if (supportS3.getIfAvailable() == null) {

            log.warn(

                    "S3 no disponible para borrador/workarea: active docviz.support.enabled o docviz.workspace-s3.enabled "

                            + "y define docviz.support.s3-endpoint (p. ej. LocalStack). Sin ello no se suben ni borran objetos en S3.");

        }

    }



    private String vectorNs() {

        return vectorIngestService.currentNamespace();

    }



    private String borradorBucket() {

        return workspaceProperties.getBorradorBucket();

    }



    private String workareaBucket() {

        return workspaceProperties.getWorkareaBucket();

    }



    public void syncDraft(String userId, String taskLabel, String draftRelativePath, String utf8Text) {

        SupportS3Service s3 = supportS3.getIfAvailable();

        if (s3 == null) {

            if (workspaceS3Enabled) {

                throw new IllegalStateException(

                        "docviz.workspace-s3.enabled=true pero el cliente S3 no está disponible (endpoint / credenciales).");

            }

            return;

        }

        if (utf8Text == null) {

            return;

        }

        String key = keyBuilder.borradorKey(vectorNs(), taskLabel, userId, draftRelativePath);

        try {

            s3.putObject(

                    borradorBucket(),

                    key,

                    utf8Text.getBytes(StandardCharsets.UTF_8),

                    "text/plain; charset=utf-8");

            log.debug("S3 borrador: {} / {}", borradorBucket(), key);

        } catch (RuntimeException e) {

            if (workspaceS3Enabled) {

                throw new IllegalStateException("No se pudo guardar el borrador en S3 (" + borradorBucket() + "): " + e.getMessage(), e);

            }

            log.warn("S3 borrador no sincronizado: {}", e.toString());

        }

    }



    public void syncAccepted(String userId, String taskLabel, String acceptedRelativePath, String utf8Text) {

        SupportS3Service s3 = supportS3.getIfAvailable();

        if (s3 == null) {

            if (workspaceS3Enabled) {

                throw new IllegalStateException(

                        "docviz.workspace-s3.enabled=true pero el cliente S3 no está disponible.");

            }

            return;

        }

        if (utf8Text == null) {

            return;

        }

        String key = keyBuilder.workareaKey(vectorNs(), taskLabel, userId, acceptedRelativePath);

        try {

            s3.putObject(

                    workareaBucket(),

                    key,

                    utf8Text.getBytes(StandardCharsets.UTF_8),

                    "text/plain; charset=utf-8");

            log.debug("S3 workarea: {} / {}", workareaBucket(), key);

        } catch (RuntimeException e) {

            if (workspaceS3Enabled) {

                throw new IllegalStateException("No se pudo guardar workarea en S3 (" + workareaBucket() + "): " + e.getMessage(), e);

            }

            log.warn("S3 workarea no sincronizado: {}", e.toString());

        }

    }



    public void deleteDraftArtifact(String userId, String taskLabel, String draftRelativePath) {

        SupportS3Service s3 = supportS3.getIfAvailable();

        if (s3 == null) {

            return;

        }

        try {

            String key = keyBuilder.borradorKey(vectorNs(), taskLabel, userId, draftRelativePath);

            s3.deleteObject(borradorBucket(), key);

            log.debug("S3 borrador eliminado: {} / {}", borradorBucket(), key);

        } catch (RuntimeException e) {

            if (workspaceS3Enabled) {

                throw new IllegalStateException("No se pudo eliminar el borrador en S3: " + e.getMessage(), e);

            }

            log.warn("S3 borrador no eliminado: {}", e.toString());

        }

    }



    public void afterWorkAreaFileIndexed(

            String userId, String taskLabel, String acceptedRelativePath, String utf8Text) {

        syncAccepted(userId, taskLabel, acceptedRelativePath, utf8Text);

        if (acceptedRelativePath == null || acceptedRelativePath.isBlank()) {

            return;

        }

        String rel = acceptedRelativePath.trim();

        String draftRel = rel.endsWith(".txt") ? rel : rel + ".txt";

        deleteDraftArtifact(userId, taskLabel, draftRel);

    }



    public boolean isS3Configured() {

        return supportS3.getIfAvailable() != null;

    }



    public List<String> listBorradorObjectKeys(String userId, String taskHuCode) {

        SupportS3Service s3 = supportS3.getIfAvailable();

        if (s3 == null) {

            return List.of();

        }

        return s3.listObjectKeys(borradorBucket(), keyBuilder.borradoresPrefix(vectorNs(), taskHuCode, userId));

    }



    public List<String> listWorkareaObjectKeys(String userId, String taskHuCode) {

        SupportS3Service s3 = supportS3.getIfAvailable();

        if (s3 == null) {

            return List.of();

        }

        return s3.listObjectKeys(workareaBucket(), keyBuilder.workareaPrefix(vectorNs(), taskHuCode, userId));

    }



    public List<S3FileUrlItem> listBorradoresWithUrls(String userId, String taskHuCode) {

        return listWithPresignedUrls(

                borradorBucket(),

                listBorradorObjectKeys(userId, taskHuCode),

                keyBuilder.borradoresPrefix(vectorNs(), taskHuCode, userId));

    }



    public List<S3FileUrlItem> listWorkareaWithUrls(String userId, String taskHuCode) {

        return listWithPresignedUrls(

                workareaBucket(),

                listWorkareaObjectKeys(userId, taskHuCode),

                keyBuilder.workareaPrefix(vectorNs(), taskHuCode, userId));

    }



    /** Borradores y workarea en un solo listado (mismo usuario y tarea). */
    public List<S3FileUrlItem> listBorradoresAndWorkareaWithUrls(String userId, String taskHuCode) {

        List<S3FileUrlItem> out = new ArrayList<>();

        out.addAll(listBorradoresWithUrls(userId, taskHuCode));

        out.addAll(listWorkareaWithUrls(userId, taskHuCode));

        return out;

    }



    private List<S3FileUrlItem> listWithPresignedUrls(String bucket, List<String> keys, String prefix) {

        SupportS3Service s3 = supportS3.getIfAvailable();

        if (s3 == null) {

            return List.of();

        }

        long ttlSec = supportProperties.getPresignedUrlTtlSeconds();

        Duration ttl = Duration.ofSeconds(ttlSec);

        List<S3FileUrlItem> out = new ArrayList<>();

        for (String key : keys) {

            if (!key.startsWith(prefix) || key.length() <= prefix.length()) {

                continue;

            }

            String fileName = key.substring(prefix.length()).replace('\\', '/');

            if (fileName.isBlank()) {

                continue;

            }

            out.add(new S3FileUrlItem(bucket, key, fileName, s3.presignGetUrl(bucket, key, ttl)));

        }

        return out;

    }



    public byte[] getBorradorObjectBytes(String key) {

        SupportS3Service s3 = supportS3.getIfAvailable();

        if (s3 == null) {

            throw new IllegalStateException("S3 no disponible");

        }

        return s3.getObjectBytes(borradorBucket(), key);

    }



    public byte[] getWorkareaObjectBytes(String key) {

        SupportS3Service s3 = supportS3.getIfAvailable();

        if (s3 == null) {

            throw new IllegalStateException("S3 no disponible");

        }

        return s3.getObjectBytes(workareaBucket(), key);

    }



    /**

     * Lee un objeto borrador/workarea solo si la clave pertenece al usuario y HU (evita filtrar por URL presignada

     * desde el navegador — mismo origen vía API).

     */

    private void ensureArtifactKeyOwned(String userId, String taskHuCode, String bucket, String key) {

        if (userId == null || userId.isBlank() || taskHuCode == null || taskHuCode.isBlank()) {

            throw new IllegalArgumentException("userId y taskHu son obligatorios");

        }

        if (bucket == null || bucket.isBlank() || key == null || key.isBlank()) {

            throw new IllegalArgumentException("bucket y key son obligatorios");

        }

        String borB = borradorBucket();

        String waB = workareaBucket();

        String b = bucket.trim();

        String k = key.trim();

        if (!borB.equals(b) && !waB.equals(b)) {

            throw new IllegalArgumentException("bucket no permitido");

        }

        String borPrefix = keyBuilder.borradoresPrefix(vectorNs(), taskHuCode, userId);

        String waPrefix = keyBuilder.workareaPrefix(vectorNs(), taskHuCode, userId);

        boolean allowed = (borB.equals(b) && k.startsWith(borPrefix)) || (waB.equals(b) && k.startsWith(waPrefix));

        if (!allowed) {

            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "La clave S3 no pertenece a esta tarea o usuario");

        }

    }



    public byte[] getArtifactBytesIfOwned(String userId, String taskHuCode, String bucket, String key) {

        ensureArtifactKeyOwned(userId, taskHuCode, bucket, key);

        SupportS3Service s3 = supportS3.getIfAvailable();

        if (s3 == null) {

            throw new IllegalStateException("S3 no disponible");

        }

        return s3.getObjectBytes(bucket.trim(), key.trim());

    }



    /** Elimina un objeto borrador o workarea si la clave pertenece al usuario y HU. */

    public void deleteArtifactIfOwned(String userId, String taskHuCode, String bucket, String key) {

        ensureArtifactKeyOwned(userId, taskHuCode, bucket, key);

        SupportS3Service s3 = supportS3.getIfAvailable();

        if (s3 == null) {

            throw new IllegalStateException("S3 no disponible");

        }

        String b = bucket.trim();

        String k = key.trim();

        s3.deleteObject(b, k);

        if (workareaBucket().equals(b)) {

            String prefix = keyBuilder.workareaPrefix(vectorNs(), taskHuCode, userId);

            if (k.startsWith(prefix) && k.length() > prefix.length()) {

                String fn = k.substring(prefix.length()).replace('\\', '/');

                if (!fn.isBlank()) {

                    vectorIngestService.deleteWorkAreaRagByFileName(fn);

                }

            }

        }

    }



    /**

     * Sobreescribe un objeto en el bucket workarea y vuelve a indexar el texto (pgvector), misma convención que

     * {@link VectorIngestService#ingestWorkAreaFile(String, String)}.

     */

    public VectorIngestResponse updateWorkareaObjectReindex(

            String userId, String taskHuCode, String objectKey, String utf8Content) {

        if (utf8Content == null || utf8Content.isBlank()) {

            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "El contenido no puede estar vacío");

        }

        String waB = workareaBucket();

        ensureArtifactKeyOwned(userId, taskHuCode, waB, objectKey);

        String prefix = keyBuilder.workareaPrefix(vectorNs(), taskHuCode, userId);

        String k = objectKey.trim();

        String fileName = k.substring(prefix.length()).replace('\\', '/');

        if (fileName.isBlank()) {

            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Nombre de objeto inválido");

        }

        SupportS3Service s3 = supportS3.getIfAvailable();

        if (s3 == null) {

            throw new IllegalStateException("S3 no disponible");

        }

        s3.putObject(

                waB,

                k,

                utf8Content.getBytes(StandardCharsets.UTF_8),

                "text/plain; charset=utf-8");

        return vectorIngestService.ingestWorkAreaFile(fileName, utf8Content);

    }



    /**

     * Sobreescribe un objeto en el bucket borradores (sin reindexar). Persistir texto ya resuelto desde la UI (p. ej.

     * conflictos DocViz sin marcadores).

     */

    public void updateBorradorObjectContent(

            String userId, String taskHuCode, String objectKey, String utf8Content) {

        if (utf8Content == null || utf8Content.isBlank()) {

            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "El contenido no puede estar vacío");

        }

        String borB = borradorBucket();

        ensureArtifactKeyOwned(userId, taskHuCode, borB, objectKey);

        SupportS3Service s3 = supportS3.getIfAvailable();

        if (s3 == null) {

            throw new IllegalStateException("S3 no disponible");

        }

        String k = objectKey.trim();

        s3.putObject(

                borB,

                k,

                utf8Content.getBytes(StandardCharsets.UTF_8),

                "text/plain; charset=utf-8");

    }

}


