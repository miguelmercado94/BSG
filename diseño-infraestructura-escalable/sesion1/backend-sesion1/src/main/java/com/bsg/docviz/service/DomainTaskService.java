package com.bsg.docviz.service;

import com.bsg.docviz.context.ChatConversationIds;
import com.bsg.docviz.crypto.CredentialCryptoService;
import com.bsg.docviz.dto.GitConnectRequest;
import com.bsg.docviz.dto.GitConnectionMode;
import com.bsg.docviz.dto.TaskContinueResponse;
import com.bsg.docviz.dto.TaskCreateRequest;
import com.bsg.docviz.dto.TaskResponse;
import com.bsg.docviz.repository.CellEntity;
import com.bsg.docviz.repository.CellJdbcRepository;
import com.bsg.docviz.repository.CellRepoEntity;
import com.bsg.docviz.repository.CellRepoJdbcRepository;
import com.bsg.docviz.repository.TaskEntity;
import com.bsg.docviz.repository.TaskJdbcRepository;
import com.bsg.docviz.security.CurrentUser;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import java.util.stream.Collectors;

@Service
public class DomainTaskService {

    public static final String PROMPT_PREFIX =
            "Actúa como un experto en soporte IT, analisalo y descomponlo en una serie de pasos que lo resuelva si es posible: ";

    /**
     * Prefijo para el chat RAG (WebSocket): la primera respuesta debe ser un único documento JSON (idealmente en un bloque
     * fence json). El backend parsea ese JSON y, si es un plan, ejecuta un paso por llamada al LLM.
     * Debe mantenerse alineado con {@code frontend-sesion1/src/lib/ragChatDisplay.ts} (misma cadena).
     * Caso informativo: solo JSON con campo {@code answer} completo; sin YAML. Caso edición: JSON más bloque YAML de propuestas.
     */
    public static final String RAG_CHAT_PROMPT_PREFIX =
            """
            Responde ÚNICAMENTE con un documento JSON válido (puedes envolverlo en ```json … ```). Sin texto antes del JSON ni después del JSON salvo el bloque YAML opcional descrito abajo.

            Esquema obligatorio del JSON:
            - Respuesta única: {"kind":"direct","answer":"markdown"}
            - Plan por pasos: {"kind":"plan","steps":[{"order":1,"summary":"…","files":[{"path":"ruta/relativa.ext","change":"…"}]}]}
            En `files` lista solo archivos a tocar en ese paso; si no hay, "files":[]. Enumera `order` 1,2,3,…

            Casos:
            1) Preguntas solo informativas (listar dependencias, explicar código, describir qué servicios o librerías usa el proyecto, resumir sin modificar archivos): usa {"kind":"direct","answer":"…"} con la respuesta completa en markdown dentro de "answer". NO añadas ningún bloque ```yaml después del JSON.

            Las menciones @[repo:ruta] y @[soporte:clave] solo acotan contexto RAG; no son por sí solas una petición de edición. Si el usuario pregunta sobre un archivo citado (dependencias, qué hace, etc.), sigue siendo caso 1): responde en "answer" sin YAML.

            No incluyas bloque ```yaml si no hay ediciones reales (blocks no vacíos). Nunca devuelvas proposals con blocks: [] solo para citar una ruta; el usuario ve la lista de archivos en la UI cuando sí hay cambios.

            2) Solo cuando el enunciado pide explícitamente crear, editar, quitar o ajustar contenido en archivos del repositorio o de soporte (p. ej. «modifica docker-compose», «añade la dependencia en build.gradle»): después del JSON cierra con un único bloque ```yaml cuya raíz sea "proposals:" (path REPO/… o LOCAL/…, new, blocks con start/end/type/lines). No pongas "proposals" dentro del JSON. Si kind es "plan", puedes posponer el ```yaml al último paso que toque archivos.

            Ejemplo solo informativo:
            ```json
            {"kind":"direct","answer":"En este repositorio las dependencias AWS aparecen en …"}
            ```

            Ejemplo con cambios de archivo (solo si el enunciado lo exige):
            ```json
            {"kind":"direct","answer":"Actualizo el compose para quitar redis."}
            ```
            ```yaml
            proposals:
            - path: REPO/findu/docker-compose.yml
              new: false
              blocks:
              - { start: 10, end: 12, type: REPLACE, lines: ["  x: y"] }
            ```

            Enunciado:


            """
                    .stripIndent();

    private final TaskJdbcRepository taskRepository;
    private final CellRepoJdbcRepository cellRepoRepository;
    private final CellJdbcRepository cellRepository;
    private final CredentialCryptoService credentialCryptoService;

    public DomainTaskService(
            TaskJdbcRepository taskRepository,
            CellRepoJdbcRepository cellRepoRepository,
            CellJdbcRepository cellRepository,
            CredentialCryptoService credentialCryptoService) {
        this.taskRepository = taskRepository;
        this.cellRepoRepository = cellRepoRepository;
        this.cellRepository = cellRepository;
        this.credentialCryptoService = credentialCryptoService;
    }

    public TaskResponse create(TaskCreateRequest req) {
        String uid = CurrentUser.require();
        CellRepoEntity linkedRepo =
                cellRepoRepository.findById(req.cellRepoId()).orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Repositorio de celda no encontrado"));
        long id =
                taskRepository.insert(
                        uid, req.huCode().trim(), req.cellRepoId(), req.enunciado().trim(), "DRAFT", null);
        String cellName = resolveCellName(linkedRepo);
        String conv = ChatConversationIds.forUserCellHuTaskIdAndThread(uid, cellName, req.huCode().trim(), id, 0);
        taskRepository.updateChatConversationId(id, conv);
        TaskEntity t = taskRepository.findById(id).orElseThrow();
        return toDto(t);
    }

    public List<TaskResponse> listMineOrAll() {
        if (CurrentUser.isAdministrator()) {
            return taskRepository.findAll().stream().map(this::toDto).collect(Collectors.toList());
        }
        return taskRepository.findByUserId(CurrentUser.require()).stream().map(this::toDto).collect(Collectors.toList());
    }

    /**
     * Lista tareas filtradas por célula (JOIN con repositorio).
     * Admin: todas las tareas de esa célula. Soporte: solo las del usuario en esa célula.
     */
    public List<TaskResponse> listForCell(long cellId) {
        if (CurrentUser.isAdministrator()) {
            return taskRepository.findByCellId(cellId).stream().map(this::toDto).collect(Collectors.toList());
        }
        return taskRepository.findByUserIdAndCellId(CurrentUser.require(), cellId).stream()
                .map(this::toDto)
                .collect(Collectors.toList());
    }

    public TaskResponse get(long id) {
        TaskEntity t = taskRepository.findById(id).orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Tarea no encontrada"));
        assertCanAccess(t);
        return toDto(t);
    }

    public TaskContinueResponse continueTask(long taskId) {
        TaskEntity t = taskRepository.findById(taskId).orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Tarea no encontrada"));
        assertCanAccess(t);
        CellRepoEntity repo = cellRepoRepository.findById(t.cellRepoId())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Repositorio no encontrado"));
        if (!repo.active()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "El repositorio configurado está inactivo");
        }
        GitConnectRequest git = buildGitConnect(repo);
        String prompt = RAG_CHAT_PROMPT_PREFIX + t.enunciado();
        String nsHint = repo.vectorNamespace();
        taskRepository.markContinued(taskId);
        String cellNameResolved = resolveCellName(repo);
        String convId = t.chatConversationId();
        if (convId == null || convId.isBlank()) {
            convId = ChatConversationIds.forUserCellHuTaskIdAndThread(t.userId(), cellNameResolved, t.huCode(), taskId, 0);
            taskRepository.updateChatConversationId(taskId, convId);
        }
        return new TaskContinueResponse(t.id(), t.huCode(), t.cellRepoId(), git, prompt, nsHint, cellNameResolved, convId);
    }

    private String resolveCellName(CellRepoEntity repo) {
        if (repo.cellId() == null) {
            return null;
        }
        return cellRepository.findById(repo.cellId()).map(CellEntity::name).orElse(null);
    }

    private void assertCanAccess(TaskEntity t) {
        if (CurrentUser.isAdministrator()) {
            return;
        }
        if (!t.userId().equals(CurrentUser.require())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "No puedes acceder a esta tarea");
        }
    }

    private TaskResponse toDto(TaskEntity t) {
        return new TaskResponse(
                t.id(),
                t.userId(),
                t.huCode(),
                t.cellRepoId(),
                t.enunciado(),
                t.status(),
                t.createdAt(),
                t.continuedAt(),
                t.chatConversationId());
    }

    private GitConnectRequest buildGitConnect(CellRepoEntity repo) {
        GitConnectRequest g = new GitConnectRequest();
        GitConnectionMode mode;
        try {
            mode = GitConnectionMode.valueOf(repo.connectionMode());
        } catch (Exception e) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Modo de conexión inválido en repositorio");
        }
        g.setMode(mode);
        g.setRepositoryUrl(repo.repositoryUrl());
        g.setLocalPath(repo.localPath());
        g.setUsername(repo.gitUsername());
        if (mode == GitConnectionMode.HTTPS_AUTH) {
            String dec = credentialCryptoService.decrypt(repo.credentialEncrypted());
            if (dec == null || dec.isBlank()) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Falta credencial para repositorio privado");
            }
            g.setToken(dec);
        }
        // Alinear con ingesta admin/célula: los chunks viven bajo repo.vectorNamespace + user_label __DOCVIZ_NS__.
        if (repo.vectorNamespace() != null && !repo.vectorNamespace().isBlank()) {
            g.setVectorNamespace(repo.vectorNamespace().trim());
        }
        return g;
    }
}
