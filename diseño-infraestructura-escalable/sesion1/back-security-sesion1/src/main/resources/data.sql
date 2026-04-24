-- Datos iniciales (PostgreSQL). Ejecutar después de schema.sql.
-- module.path_base: security-auth | docviz (ruta dentro del contexto del micro en gateway).

-- Módulos
INSERT INTO module (name, path_base, active) VALUES ('AUTH', 'security-auth', TRUE);
INSERT INTO module (name, path_base, active) VALUES ('DOCVIZ', 'docviz', TRUE);

-- Operaciones AUTH / perfil / clientes
INSERT INTO operation (path, name, http_method, module_id, permite_all, active) VALUES ('/api/v1/auth/login', 'AUTH_LOGIN', 'POST', 1, TRUE, TRUE);
INSERT INTO operation (path, name, http_method, module_id, permite_all, active) VALUES ('/api/v1/auth/refresh', 'AUTH_REFRESH', 'POST', 1, TRUE, TRUE);
INSERT INTO operation (path, name, http_method, module_id, permite_all, active) VALUES ('/api/v1/auth/logout', 'AUTH_LOGOUT', 'POST', 1, TRUE, TRUE);
INSERT INTO operation (path, name, http_method, module_id, permite_all, active) VALUES ('/api/v1/auth/validate', 'AUTH_VALIDATE', 'GET', 1, TRUE, TRUE);
INSERT INTO operation (path, name, http_method, module_id, permite_all, active) VALUES ('/api/v1/auth/forgot-password', 'AUTH_FORGOT_PASSWORD', 'POST', 1, TRUE, TRUE);
INSERT INTO operation (path, name, http_method, module_id, permite_all, active) VALUES ('/api/v1/auth/reset-password', 'AUTH_RESET_PASSWORD', 'POST', 1, TRUE, TRUE);
INSERT INTO operation (path, name, http_method, module_id, permite_all, active) VALUES ('/api/v1/customers', 'CUST_LIST', 'GET', 1, FALSE, TRUE);
INSERT INTO operation (path, name, http_method, module_id, permite_all, active) VALUES ('/api/v1/customers', 'CUST_REGISTER', 'POST', 1, TRUE, TRUE);
INSERT INTO operation (path, name, http_method, module_id, permite_all, active) VALUES ('/api/v1/profile', 'PROFILE_READ', 'GET', 1, FALSE, TRUE);
INSERT INTO operation (path, name, http_method, module_id, permite_all, active) VALUES ('/actuator/health', 'HEALTH_ACTUATOR', 'GET', 1, TRUE, TRUE);
INSERT INTO operation (path, name, http_method, module_id, permite_all, active) VALUES ('/api/public/health', 'PUBLIC_HEALTH', 'GET', 1, TRUE, TRUE);

-- Operaciones DocViz (context-path /docviz)
INSERT INTO operation (path, name, http_method, module_id, permite_all, active) VALUES ('/tags', 'DOC_TAGS', 'GET', 2, FALSE, TRUE);
INSERT INTO operation (path, name, http_method, module_id, permite_all, active) VALUES ('/connect/git', 'DOC_CONNECT_GIT', 'POST', 2, FALSE, TRUE);
INSERT INTO operation (path, name, http_method, module_id, permite_all, active) VALUES ('/files/content', 'DOC_FILES_CONTENT', 'GET', 2, FALSE, TRUE);
INSERT INTO operation (path, name, http_method, module_id, permite_all, active) VALUES ('/session/logout', 'DOC_SESSION_LOGOUT', 'POST', 2, FALSE, TRUE);
INSERT INTO operation (path, name, http_method, module_id, permite_all, active) VALUES ('/vector/ingest', 'DOC_VECTOR_INGEST', 'POST', 2, FALSE, TRUE);
INSERT INTO operation (path, name, http_method, module_id, permite_all, active) VALUES ('/vector/index', 'DOC_VECTOR_INDEX', 'DELETE', 2, FALSE, TRUE);
INSERT INTO operation (path, name, http_method, module_id, permite_all, active) VALUES ('/vector/ingest/stream', 'DOC_VECTOR_INGEST_STREAM', 'POST', 2, FALSE, TRUE);
INSERT INTO operation (path, name, http_method, module_id, permite_all, active) VALUES ('/vector/chat', 'DOC_VECTOR_CHAT', 'POST', 2, FALSE, TRUE);
INSERT INTO operation (path, name, http_method, module_id, permite_all, active) VALUES ('/vector/chat/history', 'DOC_VECTOR_CHAT_HISTORY', 'GET', 2, FALSE, TRUE);
INSERT INTO operation (path, name, http_method, module_id, permite_all, active) VALUES ('/support/markdown', 'DOC_SUPPORT_MARKDOWN', 'POST', 2, FALSE, TRUE);
INSERT INTO operation (path, name, http_method, module_id, permite_all, active) VALUES ('/support/markdown', 'DOC_SUPPORT_MARKDOWN_DELETE', 'DELETE', 2, FALSE, TRUE);
INSERT INTO operation (path, name, http_method, module_id, permite_all, active) VALUES ('/firestore/health', 'DOC_FIRESTORE_HEALTH', 'GET', 2, TRUE, TRUE);
INSERT INTO operation (path, name, http_method, module_id, permite_all, active) VALUES ('/ws/rag-chat', 'DOC_WS_RAG_CHAT', 'GET', 2, FALSE, TRUE);

-- Dominio células / tareas / listado soporte (DocViz)
INSERT INTO operation (path, name, http_method, module_id, permite_all, active) VALUES ('/cells', 'DOC_CELL_LIST', 'GET', 2, FALSE, TRUE);
INSERT INTO operation (path, name, http_method, module_id, permite_all, active) VALUES ('/tasks', 'DOC_TASK_LIST', 'GET', 2, FALSE, TRUE);
INSERT INTO operation (path, name, http_method, module_id, permite_all, active) VALUES ('/tasks', 'DOC_TASK_CREATE', 'POST', 2, FALSE, TRUE);
INSERT INTO operation (path, name, http_method, module_id, permite_all, active) VALUES ('/tasks/continue', 'DOC_TASK_CONTINUE', 'POST', 2, FALSE, TRUE);
INSERT INTO operation (path, name, http_method, module_id, permite_all, active) VALUES ('/session/vector-namespace', 'DOC_SESSION_VECTOR_NS', 'GET', 2, FALSE, TRUE);
INSERT INTO operation (path, name, http_method, module_id, permite_all, active) VALUES ('/support/markdown/objects', 'DOC_SUPPORT_OBJECTS_LIST', 'GET', 2, FALSE, TRUE);
INSERT INTO operation (path, name, http_method, module_id, permite_all, active) VALUES ('/admin/cells', 'DOC_ADMIN_CELLS_LIST', 'GET', 2, FALSE, TRUE);
INSERT INTO operation (path, name, http_method, module_id, permite_all, active) VALUES ('/admin/cells', 'DOC_ADMIN_CELLS_POST', 'POST', 2, FALSE, TRUE);
INSERT INTO operation (path, name, http_method, module_id, permite_all, active) VALUES ('/admin/cells/{id}', 'DOC_ADMIN_CELLS_PUT', 'PUT', 2, FALSE, TRUE);
INSERT INTO operation (path, name, http_method, module_id, permite_all, active) VALUES ('/admin/cells/{id}', 'DOC_ADMIN_CELLS_DELETE', 'DELETE', 2, FALSE, TRUE);
INSERT INTO operation (path, name, http_method, module_id, permite_all, active) VALUES ('/admin/cells/hints/repo-url', 'DOC_ADMIN_REPO_URL_HINT', 'GET', 2, FALSE, TRUE);
INSERT INTO operation (path, name, http_method, module_id, permite_all, active) VALUES ('/admin/cells/repo-url-hint', 'DOC_ADMIN_REPO_URL_HINT_LEGACY', 'GET', 2, FALSE, TRUE);
INSERT INTO operation (path, name, http_method, module_id, permite_all, active) VALUES ('/admin/cells/{cellId}/repos', 'DOC_ADMIN_CELL_REPOS_POST', 'POST', 2, FALSE, TRUE);
INSERT INTO operation (path, name, http_method, module_id, permite_all, active) VALUES ('/admin/cells/{cellId}/repos/{repoId}', 'DOC_ADMIN_CELL_REPO_PUT', 'PUT', 2, FALSE, TRUE);
INSERT INTO operation (path, name, http_method, module_id, permite_all, active) VALUES ('/admin/cells/{cellId}/repos/{repoId}', 'DOC_ADMIN_CELL_REPO_DELETE', 'DELETE', 2, FALSE, TRUE);
INSERT INTO operation (path, name, http_method, module_id, permite_all, active) VALUES ('/admin/cells/{id}/delete-impact', 'DOC_ADMIN_CELLS_DELETE_IMPACT', 'GET', 2, FALSE, TRUE);
INSERT INTO operation (path, name, http_method, module_id, permite_all, active) VALUES ('/admin/cells/{cellId}/repos/{repoId}/delete-impact', 'DOC_ADMIN_CELL_REPO_DELETE_IMPACT', 'GET', 2, FALSE, TRUE);

-- Roles
INSERT INTO role (name, active) VALUES ('ROLE_ADMINISTRATOR', TRUE);
INSERT INTO role (name, active) VALUES ('ROLE_SUPPORT', TRUE);

-- Administrador: todas las operaciones
INSERT INTO rol_operation (role_id, operation_id, active)
SELECT 1, id, TRUE FROM operation;

-- Soporte: DocViz sin subir/borrar .md ni crear celda admin por API (rutas /admin/* siguen bloqueadas en el micro)
INSERT INTO rol_operation (role_id, operation_id, active)
SELECT 2, id, TRUE FROM operation
WHERE name NOT IN (
    'DOC_SUPPORT_MARKDOWN',
    'DOC_SUPPORT_MARKDOWN_DELETE',
    'DOC_ADMIN_CELLS_POST',
    'DOC_ADMIN_CELLS_LIST',
    'DOC_ADMIN_CELLS_PUT',
    'DOC_ADMIN_CELLS_DELETE',
    'DOC_ADMIN_REPO_URL_HINT',
    'DOC_ADMIN_REPO_URL_HINT_LEGACY',
    'DOC_ADMIN_CELL_REPOS_POST',
    'DOC_ADMIN_CELL_REPO_PUT',
    'DOC_ADMIN_CELL_REPO_DELETE',
    'DOC_ADMIN_CELLS_DELETE_IMPACT',
    'DOC_ADMIN_CELL_REPO_DELETE_IMPACT'
);

-- Usuario demo administrador (contraseña: password — solo desarrollo)
INSERT INTO "user" (phone, username, password, email, active) VALUES (
    NULL,
    'admin',
    '$2a$10$dXJ3SW6G7P50lGmMkkmwe.20cQQubK3.HZWzG3YB1tlRy.fqvM/BG',
    'admin@bsg.local',
    TRUE
);

-- Usuario demo soporte (misma contraseña: password)
INSERT INTO "user" (phone, username, password, email, active) VALUES (
    NULL,
    'soporte',
    '$2a$10$dXJ3SW6G7P50lGmMkkmwe.20cQQubK3.HZWzG3YB1tlRy.fqvM/BG',
    'soporte@bsg.local',
    TRUE
);

-- admin01 / Admin123 — ROLE_ADMINISTRATOR (solo desarrollo)
INSERT INTO "user" (phone, username, password, email, active) VALUES (
    NULL,
    'admin01',
    '$2b$10$X1E0qhwrcDKjSROv8.IJ1OBWNgFwlnb1tynvzLVNWPbrYpQ1TabW6',
    'admin01@bsg.local',
    TRUE
);

-- soporte01 / Soporte123 — ROLE_SUPPORT (solo desarrollo)
INSERT INTO "user" (phone, username, password, email, active) VALUES (
    NULL,
    'soporte01',
    '$2b$10$eKIj7wMz3ko5xDRpwTKP5u9lsoJwsfUwDkWYG/gX/NqwWN7IMB202',
    'soporte01@bsg.local',
    TRUE
);

INSERT INTO user_rol (role_id, user_id, active) VALUES (1, 1, TRUE);
INSERT INTO user_rol (role_id, user_id, active) VALUES (2, 2, TRUE);
INSERT INTO user_rol (role_id, user_id, active) VALUES (1, 3, TRUE);
INSERT INTO user_rol (role_id, user_id, active) VALUES (2, 4, TRUE);
