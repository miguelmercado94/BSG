import { FormEvent, useEffect, useState } from "react";
import { useNavigate, useParams } from "react-router-dom";
import {
  createTask,
  deleteTask,
  fetchCellRepos,
  fetchCells,
  fetchTasks,
  getUserId,
  isSupportRole,
  updateTask,
  updateTaskStatus,
} from "../api/client";
import { saveGitConnectRequest } from "../lib/docvizGitSession";
import type { CellRepoResponse, CellResponse, TaskResponse } from "../types";

/** Badge de estado con color. */
function StatusBadge({ status }: { status: string }) {
  let label: string;
  let color: string;
  let bg: string;
  switch (status) {
    case "BORRADOR":
      label = "Borrador"; color = "#ccc"; bg = "#3a3a3a"; break;
    case "INICIADA":
      label = "En progreso"; color = "#90caf9"; bg = "#1a3a5c"; break;
    case "TERMINADA":
      label = "Terminada"; color = "#a5d6a7"; bg = "#1b3d1b"; break;
    case "CANCELADA":
      label = "Cancelada"; color = "#ef9a9a"; bg = "#3d1b1b"; break;
    default:
      label = status; color = "#ccc"; bg = "#3a3a3a";
  }
  return (
    <span style={{ display: "inline-block", padding: "0.15rem 0.5rem", borderRadius: "4px", fontSize: "0.75rem", fontWeight: 600, color, backgroundColor: bg }}>
      {label}
    </span>
  );
}

export function SupportCellTasksPage() {
  const navigate = useNavigate();
  const { cellId: cellIdParam } = useParams<{ cellId: string }>();
  const cellId = cellIdParam ?? "";

  const [cellLabel, setCellLabel] = useState("");
  const [repos, setRepos] = useState<CellRepoResponse[]>([]);
  const [tasks, setTasks] = useState<TaskResponse[]>([]);
  const [repoId, setRepoId] = useState<string | "">("");
  const [huCode, setHuCode] = useState("");
  const [enunciado, setEnunciado] = useState("");

  const [loadErr, setLoadErr] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [_indexing, _setIndexing] = useState(false);
  const [ingestErr, setIngestErr] = useState<string | null>(null);
  const [continuingId, setContinuingId] = useState<string | null>(null);

  // Edit inline state
  const [editingTaskId, setEditingTaskId] = useState<string | null>(null);
  const [editTitulo, setEditTitulo] = useState("");
  const [editEnunciado, setEditEnunciado] = useState("");
  const [editSaving, setEditSaving] = useState(false);

  const returnPath = `/support/cells/${cellId}/tasks`;

  useEffect(() => {
    if (!getUserId().trim()) {
      navigate("/", { replace: true });
      return;
    }
    if (!isSupportRole()) {
      navigate("/admin/cells", { replace: true });
      return;
    }
    if (!cellId) {
      navigate("/support/cells", { replace: true });
    }
  }, [navigate, cellId]);

  async function loadTasks() {
    try {
      const tlist = await fetchTasks(cellId);
      setTasks(tlist);
    } catch (e) {
      setLoadErr(e instanceof Error ? e.message : String(e));
    }
  }

  useEffect(() => {
    if (!cellId) return;
    let cancelled = false;
    (async () => {
      try {
        const cells: CellResponse[] = await fetchCells();
        const c = cells.find((x) => x.id === cellId);
        if (!cancelled) {
          setCellLabel(c?.name ?? `Célula ${cellId}`);
        }
        const list = await fetchCellRepos(cellId);
        if (!cancelled) {
          setRepos(list.filter((r) => r.active));
        }
        const tlist = await fetchTasks(cellId);
        if (!cancelled) setTasks(tlist);
      } catch (e) {
        if (!cancelled) setLoadErr(e instanceof Error ? e.message : String(e));
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [cellId]);

  async function onSubmitNew(e: FormEvent) {
    e.preventDefault();
    setError(null);
    setIngestErr(null);
    if (repoId === "") {
      setError("Selecciona un repositorio.");
      return;
    }
    const hu = huCode.trim();
    const en = enunciado.trim();
    if (!hu || !en) {
      setError("Código HU y enunciado son obligatorios.");
      return;
    }

    try {
      await createTask({
        huCode: hu,
        cellRepoId: repoId,
        cellId: cellId,
        enunciado: en,
      });
      // Refresh task list — the task stays as BORRADOR
      await loadTasks();
      // Reset form
      setHuCode("");
      setEnunciado("");
    } catch (err) {
      setError(err instanceof Error ? err.message : String(err));
    }
  }

  async function onContinueTask(task: TaskResponse) {
    setError(null);
    setIngestErr(null);
    setContinuingId(task.id);
    try {
      const isNewStart = task.status === "BORRADOR";
      // If BORRADOR, transition to INICIADA first
      if (isNewStart) {
        await updateTaskStatus(task.id, "INICIADA");
      }
      // Save git session so workspace doesn't redirect to login
      const repoUrl = (task as TaskResponse & { cellRepoId?: string }).cellRepoId || "";
      saveGitConnectRequest({
        mode: "HTTPS_PUBLIC",
        repositoryUrl: repoUrl,
      });
      // Limpiar dedupe del auto-send para que el enunciado se envíe como primer chat
      try {
        const dedupeKey = `docviz:autoTaskChat:${getUserId()}:task-${task.id}`;
        sessionStorage.removeItem(dedupeKey);
        sessionStorage.removeItem(`docviz:autoResumeFirst:${task.id}`);
      } catch { /* ignore */ }
      navigate("/app", {
        state: {
          connect: {
            usuario: getUserId(),
            connected: true,
            repositoryRoot: repoUrl,
            directory: { folder: "", archivos: [], folders: [] },
          },
          taskCellRepoId: repoUrl,
          initialChatPrompt: isNewStart ? (task.enunciado || undefined) : undefined,
          initialIngest: { filesProcessed: 0, chunksIndexed: 0, namespace: "", skipped: [] },
          taskContext: {
            taskId: task.id,
            huCode: task.huCode,
            enunciado: task.enunciado,
            cellLabel,
            returnPath,
            resumeWorkspaceChat: !isNewStart,
          },
        },
      });
    } catch (err) {
      setError(err instanceof Error ? err.message : String(err));
    } finally {
      setContinuingId(null);
    }
  }

  async function onDeleteTask(task: TaskResponse) {
    if (!window.confirm(`¿Eliminar la tarea "${task.huCode}"? Esta acción no se puede deshacer.`)) {
      return;
    }
    try {
      await deleteTask(task.id);
      await loadTasks();
    } catch (err) {
      setError(err instanceof Error ? err.message : String(err));
    }
  }

  function onStartEdit(task: TaskResponse) {
    setEditingTaskId(task.id);
    setEditTitulo(task.huCode);
    setEditEnunciado(task.enunciado);
  }

  function onCancelEdit() {
    setEditingTaskId(null);
    setEditTitulo("");
    setEditEnunciado("");
  }

  async function onSaveEdit(task: TaskResponse) {
    setEditSaving(true);
    try {
      await updateTask(task.id, {
        titulo: editTitulo.trim() || undefined,
        enunciadoPrincipal: editEnunciado.trim() || undefined,
      });
      await loadTasks();
      setEditingTaskId(null);
    } catch (err) {
      setError(err instanceof Error ? err.message : String(err));
    } finally {
      setEditSaving(false);
    }
  }

  const busy = _indexing;
  const selectedRepo = repos.find((x) => x.id === repoId);

  return (
    <div className="page connect-page">
      <header className="page__header">
        <h1>Tareas · {cellLabel || "…"}</h1>
        <p className="muted">
          Tus tareas en esta célula. Puedes reanudar una existente o crear una nueva con HU y enunciado.
        </p>
      </header>

      <p className="muted small">
        <button type="button" className="btn" onClick={() => navigate("/support/cells")}>
          ← Volver a células
        </button>
      </p>

      {loadErr && (
        <p className="error" role="alert">
          {loadErr}
        </p>
      )}

      {!busy && tasks.length > 0 && (
        <section className="card" style={{ marginBottom: "1rem" }}>
          <h2 className="h3">Mis tareas en esta célula</h2>
          <ul className="muted small" style={{ listStyle: "none", padding: 0 }}>
            {tasks.map((t) => (
              <li
                key={t.id}
                style={{
                  display: "flex",
                  flexWrap: "wrap",
                  alignItems: "center",
                  gap: "0.5rem",
                  marginBottom: "0.75rem",
                  paddingBottom: "0.75rem",
                  borderBottom: "1px solid #2d3a4d",
                }}
              >
                <strong>{t.huCode}</strong>
                <StatusBadge status={t.status} />
                <span style={{ flex: "1 1 100%", fontSize: "0.9rem" }}>
                  {t.enunciado.slice(0, 160)}{t.enunciado.length > 160 ? "…" : ""}
                </span>

                {/* Inline edit form */}
                {editingTaskId === t.id && (
                  <div style={{ flex: "1 1 100%", marginTop: "0.5rem" }}>
                    <label className="field" style={{ marginBottom: "0.4rem" }}>
                      <span>Título</span>
                      <input
                        value={editTitulo}
                        onChange={(ev) => setEditTitulo(ev.target.value)}
                        disabled={editSaving}
                      />
                    </label>
                    <label className="field" style={{ marginBottom: "0.4rem" }}>
                      <span>Enunciado</span>
                      <textarea
                        value={editEnunciado}
                        onChange={(ev) => setEditEnunciado(ev.target.value)}
                        rows={3}
                        disabled={editSaving}
                      />
                    </label>
                    <div style={{ display: "flex", gap: "0.5rem" }}>
                      <button
                        type="button"
                        className="btn primary btn--small"
                        disabled={editSaving}
                        onClick={() => onSaveEdit(t)}
                      >
                        {editSaving ? "Guardando…" : "Guardar"}
                      </button>
                      <button
                        type="button"
                        className="btn btn--small"
                        disabled={editSaving}
                        onClick={onCancelEdit}
                      >
                        Cancelar
                      </button>
                    </div>
                  </div>
                )}

                {/* Action buttons */}
                <div style={{ display: "flex", gap: "0.5rem", alignItems: "center" }}>
                  {t.status === "BORRADOR" && editingTaskId !== t.id && (
                    <>
                      <button
                        type="button"
                        className="btn btn--small"
                        onClick={() => onStartEdit(t)}
                      >
                        Editar
                      </button>
                      <button
                        type="button"
                        className="btn btn--small"
                        style={{ color: "#ef5350", borderColor: "#ef5350" }}
                        onClick={() => onDeleteTask(t)}
                      >
                        Eliminar
                      </button>
                    </>
                  )}

                  {(t.status === "BORRADOR" || t.status === "INICIADA") && (
                    <button
                      type="button"
                      className="btn primary btn--small"
                      disabled={continuingId === t.id}
                      onClick={() => onContinueTask(t)}
                    >
                      {continuingId === t.id
                        ? "Abriendo…"
                        : t.status === "BORRADOR"
                          ? "Iniciar en workspace"
                          : "Continuar en workspace"}
                    </button>
                  )}

                  {(t.status === "TERMINADA" || t.status === "CANCELADA") && (
                    <button
                      type="button"
                      className="btn btn--small"
                      disabled
                      title="Tarea finalizada"
                      style={{ opacity: 0.5, cursor: "not-allowed" }}
                    >
                      Tarea finalizada
                    </button>
                  )}
                </div>
              </li>
            ))}
          </ul>
        </section>
      )}

      {!busy && (
        <form className="card" onSubmit={onSubmitNew}>
          <h2 className="h3">Nueva tarea</h2>
          <label className="field">
            <span>Repositorio</span>
            <select
              value={repoId === "" ? "" : String(repoId)}
              onChange={(ev) => {
                setRepoId(ev.target.value);
              }}
              required
              disabled={repos.length === 0}
            >
              <option value="">— Elegir —</option>
              {repos.map((r) => (
                <option key={r.id} value={r.id}>
                  {r.displayName} ({r.connectionMode})
                </option>
              ))}
            </select>
          </label>

          {selectedRepo && (
            <p className="muted small">
              URL: <code className="muted">{selectedRepo.repositoryUrl}</code>
            </p>
          )}

          <label className="field">
            <span>Código HU</span>
            <input
              value={huCode}
              onChange={(ev) => setHuCode(ev.target.value)}
              placeholder="p. ej. HU-12345"
              required
              maxLength={120}
            />
          </label>

          <label className="field">
            <span>Enunciado del caso</span>
            <textarea
              value={enunciado}
              onChange={(ev) => setEnunciado(ev.target.value)}
              rows={5}
              required
              minLength={1}
              title="El enunciado es obligatorio y no puede ser solo espacios."
              placeholder="Describe el problema o la petición de soporte…"
            />
          </label>

          {error && <p className="error">{error}</p>}
          {ingestErr && <p className="error">{ingestErr}</p>}

          <button type="submit" className="btn primary">
            Crear tarea
          </button>
        </form>
      )}
    </div>
  );
}
