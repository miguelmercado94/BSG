-- =============================================================================
-- Migración: operaciones DocViz admin "pending index" (indexación por archivo).
-- PostgreSQL. module_id = 2 → tabla module nombre DOCVIZ (como en data.sql inicial).
--
-- Opción A — INCREMENTAL (recomendada): no borra nada; solo añade filas si faltan.
-- Opción B — RESEED operation + rol_operation: borra TODAS las operaciones y permisos,
--           luego debes ejecutar el bloque grande de INSERT (ver abajo / data.sql).
-- =============================================================================

-- -----------------------------------------------------------------------------
-- OPCIÓN A — Incremental (ejecutar una vez por entorno)
-- -----------------------------------------------------------------------------

INSERT INTO operation (path, name, http_method, module_id, permite_all, active)
SELECT '/admin/cells/pending/index/begin', 'DOC_ADMIN_PENDING_INDEX_BEGIN', 'POST', 2, FALSE, TRUE
WHERE NOT EXISTS (SELECT 1 FROM operation WHERE name = 'DOC_ADMIN_PENDING_INDEX_BEGIN');

INSERT INTO operation (path, name, http_method, module_id, permite_all, active)
SELECT '/admin/cells/pending/{repoId}/ingest-paths', 'DOC_ADMIN_PENDING_INGEST_PATHS', 'GET', 2, FALSE, TRUE
WHERE NOT EXISTS (SELECT 1 FROM operation WHERE name = 'DOC_ADMIN_PENDING_INGEST_PATHS');

INSERT INTO operation (path, name, http_method, module_id, permite_all, active)
SELECT '/admin/cells/pending/{repoId}/ingest-one', 'DOC_ADMIN_PENDING_INGEST_ONE', 'POST', 2, FALSE, TRUE
WHERE NOT EXISTS (SELECT 1 FROM operation WHERE name = 'DOC_ADMIN_PENDING_INGEST_ONE');

INSERT INTO operation (path, name, http_method, module_id, permite_all, active)
SELECT '/admin/cells/pending/{repoId}/index/finish', 'DOC_ADMIN_PENDING_INDEX_FINISH', 'POST', 2, FALSE, TRUE
WHERE NOT EXISTS (SELECT 1 FROM operation WHERE name = 'DOC_ADMIN_PENDING_INDEX_FINISH');

INSERT INTO operation (path, name, http_method, module_id, permite_all, active)
SELECT '/admin/cells/pending/{repoId}/index/abort', 'DOC_ADMIN_PENDING_INDEX_ABORT', 'POST', 2, FALSE, TRUE
WHERE NOT EXISTS (SELECT 1 FROM operation WHERE name = 'DOC_ADMIN_PENDING_INDEX_ABORT');

-- Administrador: todas las operaciones (incluidas las nuevas) — idempotente
INSERT INTO rol_operation (role_id, operation_id, active)
SELECT 1, o.id, TRUE
FROM operation o
WHERE NOT EXISTS (
    SELECT 1 FROM rol_operation ro
    WHERE ro.role_id = 1 AND ro.operation_id = o.id
);

-- Soporte: quitar estas rutas admin si ya estaban enlazadas por error (idempotente)
DELETE FROM rol_operation
WHERE role_id = 2
  AND operation_id IN (
      SELECT id FROM operation
      WHERE name IN (
          'DOC_ADMIN_PENDING_INDEX_BEGIN',
          'DOC_ADMIN_PENDING_INGEST_PATHS',
          'DOC_ADMIN_PENDING_INGEST_ONE',
          'DOC_ADMIN_PENDING_INDEX_FINISH',
          'DOC_ADMIN_PENDING_INDEX_ABORT'
      )
  );

-- (Opcional) Volver a aplicar la política "soporte = todas las operaciones excepto lista negra"
-- Solo si en vuestro despliegue rehacéis el rol soporte así; descomentar y ajustar role_id si hace falta.
-- DELETE FROM rol_operation WHERE role_id = 2;
-- INSERT INTO rol_operation (role_id, operation_id, active)
-- SELECT 2, id, TRUE FROM operation
-- WHERE name NOT IN (
--     'DOC_SUPPORT_MARKDOWN',
--     'DOC_SUPPORT_MARKDOWN_DELETE',
--     'DOC_ADMIN_CELLS_POST',
--     'DOC_ADMIN_CELLS_LIST',
--     'DOC_ADMIN_CELLS_PUT',
--     'DOC_ADMIN_CELLS_DELETE',
--     'DOC_ADMIN_REPO_URL_HINT',
--     'DOC_ADMIN_REPO_URL_HINT_LEGACY',
--     'DOC_ADMIN_CELL_REPOS_POST',
--     'DOC_ADMIN_CELL_REPO_PUT',
--     'DOC_ADMIN_CELL_REPO_DELETE',
--     'DOC_ADMIN_CELLS_DELETE_IMPACT',
--     'DOC_ADMIN_CELL_REPO_DELETE_IMPACT',
--     'DOC_ADMIN_PENDING_INDEX_BEGIN',
--     'DOC_ADMIN_PENDING_INGEST_PATHS',
--     'DOC_ADMIN_PENDING_INGEST_ONE',
--     'DOC_ADMIN_PENDING_INDEX_FINISH',
--     'DOC_ADMIN_PENDING_INDEX_ABORT'
-- );

-- -----------------------------------------------------------------------------
-- OPCIÓN B — Vaciar operaciones y permisos (CUIDADO: afecta a TODOS los clientes del API)
-- No borra users/roles/módulos. Tras el DELETE, hay que reinsertar TODAS las filas
-- de `operation` del fichero data.sql (líneas de INSERT operation), luego:
--   INSERT INTO rol_operation (role_id, operation_id, active) SELECT 1, id, TRUE FROM operation;
--   y el bloque INSERT rol para role_id = 2 con el NOT IN (…completo…).
--
-- BEGIN;
-- DELETE FROM rol_operation;
-- DELETE FROM operation;
-- -- aquí pegar TODOS los INSERT INTO operation ... de data.sql
-- -- luego los dos INSERT INTO rol_operation ... (admin y soporte) como en data.sql
-- COMMIT;
-- -----------------------------------------------------------------------------
