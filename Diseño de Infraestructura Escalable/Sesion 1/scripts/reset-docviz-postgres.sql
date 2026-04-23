-- Vacía dominio DocViz + embeddings en la BD `docviz` (PostgreSQL del compose, puerto host 5432).
-- Ejemplo:
--   docker exec -i docviz-postgres psql -U docviz -d docviz -v ON_ERROR_STOP=1 -f - < scripts/reset-docviz-postgres.sql
-- O desde la raíz Sesion 1 en PowerShell:
--   Get-Content scripts/reset-docviz-postgres.sql | docker exec -i docviz-postgres psql -U docviz -d docviz -v ON_ERROR_STOP=1

TRUNCATE TABLE docviz_vector_chunk RESTART IDENTITY;
TRUNCATE TABLE docviz_task, docviz_cell_repo, docviz_cell RESTART IDENTITY CASCADE;
