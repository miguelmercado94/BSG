package com.bsg.docviz.repository;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import java.sql.PreparedStatement;
import java.sql.Timestamp;
import java.sql.Types;
import java.time.Instant;
import java.util.List;
import java.util.Optional;

@Repository
public class CellRepoJdbcRepository {

    private static final RowMapper<CellRepoEntity> MAPPER = (rs, rowNum) -> {
        Instant lastIngest = rs.getTimestamp("last_ingest_at") != null ? rs.getTimestamp("last_ingest_at").toInstant() : null;
        Integer files = rs.getObject("last_ingest_files") != null ? rs.getInt("last_ingest_files") : null;
        Integer chunks = rs.getObject("last_ingest_chunks") != null ? rs.getInt("last_ingest_chunks") : null;
        Long cellIdObj = rs.getObject("cell_id") != null ? rs.getLong("cell_id") : null;
        return new CellRepoEntity(
                rs.getLong("id"),
                cellIdObj,
                rs.getString("display_name"),
                rs.getString("repository_url"),
                rs.getString("connection_mode"),
                rs.getString("git_username"),
                rs.getString("credential_encrypted"),
                rs.getString("local_path"),
                rs.getString("tags_csv"),
                rs.getString("vector_namespace"),
                rs.getBoolean("active"),
                rs.getTimestamp("created_at").toInstant(),
                rs.getTimestamp("updated_at").toInstant(),
                lastIngest,
                files,
                chunks,
                rs.getString("last_ingest_skipped_json"),
                rs.getBoolean("linked_without_reindex"));
    };

    private static final String SELECT_COLUMNS =
            """
            SELECT id, cell_id, display_name, repository_url, connection_mode, git_username,
                   credential_encrypted, local_path, tags_csv, vector_namespace, active, created_at, updated_at,
                   last_ingest_at, last_ingest_files, last_ingest_chunks, last_ingest_skipped_json, linked_without_reindex
            """;

    private final JdbcTemplate jdbc;
    private final TaskJdbcRepository taskJdbcRepository;

    public CellRepoJdbcRepository(JdbcTemplate jdbc, TaskJdbcRepository taskJdbcRepository) {
        this.jdbc = jdbc;
        this.taskJdbcRepository = taskJdbcRepository;
    }

    public List<CellRepoEntity> findByCellId(long cellId) {
        return jdbc.query(
                SELECT_COLUMNS + " FROM docviz_cell_repo WHERE cell_id = ? ORDER BY display_name",
                MAPPER,
                cellId);
    }

    public Optional<CellRepoEntity> findById(long id) {
        List<CellRepoEntity> list =
                jdbc.query(SELECT_COLUMNS + " FROM docviz_cell_repo WHERE id = ?", MAPPER, id);
        return list.isEmpty() ? Optional.empty() : Optional.of(list.getFirst());
    }

    /** Cualquier fila con la misma clave (hint o enlace entre células). */
    public Optional<CellRepoEntity> findFirstByRepositoryKey(String normalizedKey) {
        if (normalizedKey == null || normalizedKey.isBlank()) {
            return Optional.empty();
        }
        List<CellRepoEntity> list =
                jdbc.query(
                        SELECT_COLUMNS
                                + " FROM docviz_cell_repo WHERE repository_key_norm = ? ORDER BY id ASC LIMIT 1",
                        MAPPER,
                        normalizedKey);
        return list.isEmpty() ? Optional.empty() : Optional.of(list.getFirst());
    }

    /** Repo indexado sin célula (pendiente de “Guardar”). */
    public Optional<CellRepoEntity> findOrphanByRepositoryKey(String normalizedKey) {
        if (normalizedKey == null || normalizedKey.isBlank()) {
            return Optional.empty();
        }
        List<CellRepoEntity> list =
                jdbc.query(
                        SELECT_COLUMNS
                                + " FROM docviz_cell_repo WHERE repository_key_norm = ? AND cell_id IS NULL LIMIT 1",
                        MAPPER,
                        normalizedKey);
        return list.isEmpty() ? Optional.empty() : Optional.of(list.getFirst());
    }

    public boolean existsByCellIdAndRepositoryKeyNorm(long cellId, String normalizedKey) {
        if (normalizedKey == null || normalizedKey.isBlank()) {
            return false;
        }
        Integer n =
                jdbc.queryForObject(
                        "SELECT COUNT(*)::int FROM docviz_cell_repo WHERE cell_id = ? AND repository_key_norm = ?",
                        Integer.class,
                        cellId,
                        normalizedKey);
        return n != null && n > 0;
    }

    public boolean existsOtherInCellWithRepositoryKeyNorm(long cellId, long excludeLinkId, String normalizedKey) {
        if (normalizedKey == null || normalizedKey.isBlank()) {
            return false;
        }
        Integer n =
                jdbc.queryForObject(
                        "SELECT COUNT(*)::int FROM docviz_cell_repo WHERE cell_id = ? AND repository_key_norm = ? AND id <> ?",
                        Integer.class,
                        cellId,
                        normalizedKey,
                        excludeLinkId);
        return n != null && n > 0;
    }

    /**
     * {@code cellId} null = fila huérfana (indexada, sin célula hasta “Guardar”).
     */
    public long insert(
            Long cellId,
            String displayName,
            String repositoryUrl,
            String connectionMode,
            String gitUsername,
            String credentialEncrypted,
            String localPath,
            String tagsCsv,
            String vectorNamespace,
            String repositoryKeyNorm) {
        Timestamp now = Timestamp.from(Instant.now());
        Long id =
                jdbc.query(
                        connection -> {
                            PreparedStatement ps =
                                    connection.prepareStatement(
                                            """
                                            INSERT INTO docviz_cell_repo (cell_id, display_name, repository_url, connection_mode,
                                                git_username, credential_encrypted, local_path, tags_csv, vector_namespace,
                                                repository_key_norm, linked_without_reindex, active, created_at, updated_at)
                                            VALUES (?,?,?,?,?,?,?,?,?,?,FALSE,TRUE,?,?)
                                            RETURNING id
                                            """);
                            if (cellId == null) {
                                ps.setNull(1, Types.BIGINT);
                            } else {
                                ps.setLong(1, cellId);
                            }
                            ps.setString(2, displayName);
                            ps.setString(3, repositoryUrl);
                            ps.setString(4, connectionMode);
                            ps.setString(5, gitUsername);
                            ps.setString(6, credentialEncrypted);
                            ps.setString(7, localPath);
                            ps.setString(8, tagsCsv);
                            ps.setString(9, vectorNamespace);
                            ps.setString(10, repositoryKeyNorm);
                            ps.setTimestamp(11, now);
                            ps.setTimestamp(12, now);
                            return ps;
                        },
                        rs -> {
                            if (!rs.next()) {
                                throw new IllegalStateException("INSERT docviz_cell_repo: no se devolvió id");
                            }
                            return rs.getLong(1);
                        });
        return id;
    }

    /**
     * Enlace sin célula (pendiente de asignación): misma metadata que {@link #insertLinkedFromCanonical(long, CellRepoEntity, String, String, String)}
     * pero {@code cell_id IS NULL}.
     */
    public long insertLinkedFromCanonicalOrphan(
            CellRepoEntity src,
            String tagsCsv,
            String repositoryKeyNorm,
            String displayName) {
        Timestamp now = Timestamp.from(Instant.now());
        Long id =
                jdbc.query(
                        connection -> {
                            PreparedStatement ps =
                                    connection.prepareStatement(
                                            """
                                            INSERT INTO docviz_cell_repo (cell_id, display_name, repository_url, connection_mode,
                                                git_username, credential_encrypted, local_path, tags_csv, vector_namespace,
                                                repository_key_norm, linked_without_reindex, active, created_at, updated_at,
                                                last_ingest_at, last_ingest_files, last_ingest_chunks, last_ingest_skipped_json)
                                            VALUES (?,?,?,?,?,?,?,?,?,?,TRUE,TRUE,?,?,?,?,?,?)
                                            RETURNING id
                                            """);
                            int i = 1;
                            ps.setNull(i++, Types.BIGINT);
                            ps.setString(i++, displayName);
                            ps.setString(i++, src.repositoryUrl());
                            ps.setString(i++, src.connectionMode());
                            ps.setString(i++, src.gitUsername());
                            ps.setString(i++, src.credentialEncrypted());
                            ps.setString(i++, src.localPath());
                            ps.setString(i++, tagsCsv);
                            ps.setString(i++, src.vectorNamespace());
                            ps.setString(i++, repositoryKeyNorm);
                            ps.setTimestamp(i++, now);
                            ps.setTimestamp(i++, now);
                            if (src.lastIngestAt() != null) {
                                ps.setTimestamp(i++, Timestamp.from(src.lastIngestAt()));
                            } else {
                                ps.setNull(i++, Types.TIMESTAMP);
                            }
                            if (src.lastIngestFiles() != null) {
                                ps.setInt(i++, src.lastIngestFiles());
                            } else {
                                ps.setNull(i++, Types.INTEGER);
                            }
                            if (src.lastIngestChunks() != null) {
                                ps.setInt(i++, src.lastIngestChunks());
                            } else {
                                ps.setNull(i++, Types.INTEGER);
                            }
                            ps.setString(i, src.lastIngestSkippedJson());
                            return ps;
                        },
                        rs -> {
                            if (!rs.next()) {
                                throw new IllegalStateException("INSERT docviz_cell_repo (huérfano enlace): no se devolvió id");
                            }
                            return rs.getLong(1);
                        });
        return id;
    }

    /** Misma URL en otra célula: copia canónico + estado de ingest; no reindexa. */
    public long insertLinkedFromCanonical(
            long cellId,
            CellRepoEntity src,
            String tagsCsv,
            String repositoryKeyNorm,
            String displayName) {
        Timestamp now = Timestamp.from(Instant.now());
        Long id =
                jdbc.query(
                        connection -> {
                            PreparedStatement ps =
                                    connection.prepareStatement(
                                            """
                                            INSERT INTO docviz_cell_repo (cell_id, display_name, repository_url, connection_mode,
                                                git_username, credential_encrypted, local_path, tags_csv, vector_namespace,
                                                repository_key_norm, linked_without_reindex, active, created_at, updated_at,
                                                last_ingest_at, last_ingest_files, last_ingest_chunks, last_ingest_skipped_json)
                                            VALUES (?,?,?,?,?,?,?,?,?,?,TRUE,TRUE,?,?,?,?,?,?)
                                            RETURNING id
                                            """);
                            int i = 1;
                            ps.setLong(i++, cellId);
                            ps.setString(i++, displayName);
                            ps.setString(i++, src.repositoryUrl());
                            ps.setString(i++, src.connectionMode());
                            ps.setString(i++, src.gitUsername());
                            ps.setString(i++, src.credentialEncrypted());
                            ps.setString(i++, src.localPath());
                            ps.setString(i++, tagsCsv);
                            ps.setString(i++, src.vectorNamespace());
                            ps.setString(i++, repositoryKeyNorm);
                            ps.setTimestamp(i++, now);
                            ps.setTimestamp(i++, now);
                            if (src.lastIngestAt() != null) {
                                ps.setTimestamp(i++, Timestamp.from(src.lastIngestAt()));
                            } else {
                                ps.setNull(i++, Types.TIMESTAMP);
                            }
                            if (src.lastIngestFiles() != null) {
                                ps.setInt(i++, src.lastIngestFiles());
                            } else {
                                ps.setNull(i++, Types.INTEGER);
                            }
                            if (src.lastIngestChunks() != null) {
                                ps.setInt(i++, src.lastIngestChunks());
                            } else {
                                ps.setNull(i++, Types.INTEGER);
                            }
                            ps.setString(i, src.lastIngestSkippedJson());
                            return ps;
                        },
                        rs -> {
                            if (!rs.next()) {
                                throw new IllegalStateException("INSERT docviz_cell_repo (enlace): no se devolvió id");
                            }
                            return rs.getLong(1);
                        });
        return id;
    }

    public boolean update(
            long id,
            String displayName,
            String repositoryUrl,
            String connectionMode,
            String gitUsername,
            String credentialEncrypted,
            String localPath,
            String tagsCsv,
            String vectorNamespace,
            String repositoryKeyNorm) {
        return jdbc.update(
                """
                UPDATE docviz_cell_repo SET display_name = ?, repository_url = ?, connection_mode = ?,
                    git_username = ?, credential_encrypted = ?, local_path = ?, tags_csv = ?, vector_namespace = ?,
                    repository_key_norm = ?, updated_at = ?
                WHERE id = ?
                """,
                displayName,
                repositoryUrl,
                connectionMode,
                gitUsername,
                credentialEncrypted,
                localPath,
                tagsCsv,
                vectorNamespace,
                repositoryKeyNorm,
                Timestamp.from(Instant.now()),
                id) > 0;
    }

    public void updateLastIngest(long id, Instant at, int files, int chunks, String skippedJson) {
        jdbc.update(
                """
                UPDATE docviz_cell_repo SET last_ingest_at = ?, last_ingest_files = ?, last_ingest_chunks = ?,
                    last_ingest_skipped_json = ?, linked_without_reindex = FALSE, updated_at = ?
                WHERE id = ?
                """,
                Timestamp.from(at),
                files,
                chunks,
                skippedJson,
                Timestamp.from(Instant.now()),
                id);
    }

    @Transactional
    public boolean delete(long id) {
        taskJdbcRepository.deleteByCellRepoId(id);
        return jdbc.update("DELETE FROM docviz_cell_repo WHERE id = ?", id) > 0;
    }

    /** Asigna un repo huérfano a una célula. Solo filas con {@code cell_id IS NULL}. */
    public boolean updateCellIdWhereNull(long repoId, long newCellId) {
        return jdbc.update(
                """
                UPDATE docviz_cell_repo SET cell_id = ?, updated_at = ?
                WHERE id = ? AND cell_id IS NULL
                """,
                newCellId,
                Timestamp.from(Instant.now()),
                repoId)
                > 0;
    }
}
