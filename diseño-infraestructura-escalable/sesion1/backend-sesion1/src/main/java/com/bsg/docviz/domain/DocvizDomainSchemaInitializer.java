package com.bsg.docviz.domain;

import com.bsg.docviz.util.RepositoryUrlNormalizer;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.core.annotation.Order;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

/**
 * DDL idempotente: células, repos configurados y tareas (dominio BSG).
 */
@Component
@Order(1)
public class DocvizDomainSchemaInitializer implements ApplicationRunner {

    private static final Logger log = LoggerFactory.getLogger(DocvizDomainSchemaInitializer.class);

    private final JdbcTemplate jdbcTemplate;

    public DocvizDomainSchemaInitializer(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    @Override
    public void run(ApplicationArguments args) {
        jdbcTemplate.execute("""
                CREATE TABLE IF NOT EXISTS docviz_cell (
                    id BIGSERIAL PRIMARY KEY,
                    name VARCHAR(200) NOT NULL,
                    description TEXT,
                    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
                    created_by VARCHAR(200) NOT NULL
                )
                """);
        jdbcTemplate.execute("""
                CREATE TABLE IF NOT EXISTS docviz_cell_repo (
                    id BIGSERIAL PRIMARY KEY,
                    cell_id BIGINT NOT NULL REFERENCES docviz_cell(id) ON DELETE CASCADE,
                    display_name VARCHAR(200) NOT NULL,
                    repository_url TEXT NOT NULL,
                    connection_mode VARCHAR(32) NOT NULL,
                    git_username VARCHAR(500),
                    credential_encrypted TEXT,
                    local_path TEXT,
                    tags_csv VARCHAR(2000),
                    vector_namespace VARCHAR(500),
                    active BOOLEAN NOT NULL DEFAULT TRUE,
                    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
                    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
                )
                """);
        jdbcTemplate.execute("""
                CREATE INDEX IF NOT EXISTS idx_docviz_cell_repo_cell ON docviz_cell_repo(cell_id)
                """);
        try {
            jdbcTemplate.execute("ALTER TABLE docviz_cell_repo ADD COLUMN IF NOT EXISTS last_ingest_at TIMESTAMPTZ");
            jdbcTemplate.execute("ALTER TABLE docviz_cell_repo ADD COLUMN IF NOT EXISTS last_ingest_files INTEGER");
            jdbcTemplate.execute("ALTER TABLE docviz_cell_repo ADD COLUMN IF NOT EXISTS last_ingest_chunks INTEGER");
            jdbcTemplate.execute(
                    "ALTER TABLE docviz_cell_repo ADD COLUMN IF NOT EXISTS last_ingest_skipped_json TEXT");
        } catch (Exception e) {
            log.warn("ALTER docviz_cell_repo columnas de ingesta: {}", e.getMessage());
        }
        jdbcTemplate.execute("""
                CREATE TABLE IF NOT EXISTS docviz_task (
                    id BIGSERIAL PRIMARY KEY,
                    user_id VARCHAR(200) NOT NULL,
                    hu_code VARCHAR(120) NOT NULL,
                    cell_repo_id BIGINT NOT NULL REFERENCES docviz_cell_repo(id),
                    enunciado TEXT NOT NULL,
                    status VARCHAR(32) NOT NULL DEFAULT 'DRAFT',
                    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
                    continued_at TIMESTAMPTZ
                )
                """);
        jdbcTemplate.execute("""
                CREATE INDEX IF NOT EXISTS idx_docviz_task_user ON docviz_task(user_id)
                """);
        try {
            jdbcTemplate.execute(
                    "ALTER TABLE docviz_task ADD COLUMN IF NOT EXISTS chat_conversation_id VARCHAR(500)");
        } catch (Exception e) {
            log.warn("ALTER docviz_task chat_conversation_id: {}", e.getMessage());
        }
        try {
            jdbcTemplate.execute("ALTER TABLE docviz_cell_repo ADD COLUMN IF NOT EXISTS repository_key_norm TEXT");
            backfillRepositoryKeyNorm();
            deduplicateCellReposByKeyNorm();
            jdbcTemplate.execute("ALTER TABLE docviz_cell_repo ALTER COLUMN repository_key_norm SET NOT NULL");
        } catch (Exception e) {
            log.warn(
                    "Migración repository_key_norm (relleno / deduplicación / NOT NULL): {}",
                    e.getMessage());
        }
        try {
            jdbcTemplate.execute(
                    "ALTER TABLE docviz_cell_repo ADD COLUMN IF NOT EXISTS linked_without_reindex BOOLEAN NOT NULL DEFAULT FALSE");
        } catch (Exception e) {
            log.warn("ALTER docviz_cell_repo linked_without_reindex: {}", e.getMessage());
        }
        try {
            jdbcTemplate.execute("ALTER TABLE docviz_cell_repo ALTER COLUMN cell_id DROP NOT NULL");
        } catch (Exception e) {
            log.warn("ALTER docviz_cell_repo cell_id nullable: {}", e.getMessage());
        }
        try {
            jdbcTemplate.execute("DROP INDEX IF EXISTS uq_docviz_cell_repo_cell_key");
        } catch (Exception e) {
            log.warn("DROP uq_docviz_cell_repo_cell_key: {}", e.getMessage());
        }
        try {
            jdbcTemplate.execute(
                    """
                    CREATE UNIQUE INDEX IF NOT EXISTS uq_docviz_cell_repo_cell_key_nn
                    ON docviz_cell_repo (cell_id, repository_key_norm)
                    WHERE cell_id IS NOT NULL
                    """);
        } catch (Exception e) {
            log.warn("CREATE uq_docviz_cell_repo_cell_key_nn: {}", e.getMessage());
        }
        try {
            jdbcTemplate.execute(
                    """
                    CREATE UNIQUE INDEX IF NOT EXISTS uq_docviz_cell_repo_orphan_key
                    ON docviz_cell_repo (repository_key_norm)
                    WHERE cell_id IS NULL
                    """);
        } catch (Exception e) {
            log.warn("CREATE uq_docviz_cell_repo_orphan_key: {}", e.getMessage());
        }
        try {
            jdbcTemplate.execute("DROP INDEX IF EXISTS uq_docviz_cell_repo_repository_key_norm");
        } catch (Exception e) {
            log.warn("DROP índice global repository_key_norm: {}", e.getMessage());
        }
        try {
            jdbcTemplate.execute("""
                    CREATE UNIQUE INDEX IF NOT EXISTS uq_docviz_cell_name_norm ON docviz_cell (lower(btrim(name)))
                    """);
        } catch (Exception e) {
            log.warn(
                    "No se pudo crear índice único uq_docviz_cell_name_norm (p. ej. ya existen células duplicadas). "
                            + "Elimina duplicados manualmente y reinicia, o confía en la validación en aplicación: {}",
                    e.getMessage());
        }
        log.info("Esquema dominio docviz_cell / docviz_cell_repo / docviz_task comprobado");
    }

    private void backfillRepositoryKeyNorm() {
        jdbcTemplate.query(
                "SELECT id, repository_url, local_path, connection_mode FROM docviz_cell_repo",
                rs -> {
                    while (rs.next()) {
                        long id = rs.getLong("id");
                        String key =
                                RepositoryUrlNormalizer.normalizeRepositoryKey(
                                        rs.getString("repository_url"),
                                        rs.getString("local_path"),
                                        rs.getString("connection_mode"));
                        if (key == null || key.isBlank()) {
                            key = "__invalid__:" + id;
                        }
                        jdbcTemplate.update(
                                "UPDATE docviz_cell_repo SET repository_key_norm = ? WHERE id = ?", key, id);
                    }
                    return null;
                });
    }

    /**
     * Una fila por URL normalizada: reasigna tareas al id conservado (mínimo por clave) y borra duplicados.
     */
    private void deduplicateCellReposByKeyNorm() {
        jdbcTemplate.update(
                """
                UPDATE docviz_task t
                SET cell_repo_id = s.keeper
                FROM (
                    SELECT id, MIN(id) OVER (PARTITION BY repository_key_norm) AS keeper
                    FROM docviz_cell_repo
                ) s
                WHERE t.cell_repo_id = s.id AND s.id != s.keeper
                """);
        int removed =
                jdbcTemplate.update(
                        """
                        DELETE FROM docviz_cell_repo r
                        WHERE r.id IN (
                            SELECT id FROM (
                                SELECT id, MIN(id) OVER (PARTITION BY repository_key_norm) AS keeper
                                FROM docviz_cell_repo
                            ) x WHERE x.id != x.keeper
                        )
                        """);
        if (removed > 0) {
            log.info("Deduplicación docviz_cell_repo: eliminadas {} filas repetidas por repository_key_norm", removed);
        }
    }
}
