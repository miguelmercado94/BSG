import { FormEvent, useEffect, useState } from "react";
import { useNavigate, useParams } from "react-router-dom";
import {
  connectGit,
  continueTask,
  createTask,
  fetchCellRepos,
  fetchCells,
  fetchTasks,
  getUserId,
  isSupportRole,
  vectorIngestStream,
} from "../api/client";
import { saveGitConnectRequest } from "../lib/docvizGitSession";
import type { CellRepoResponse, CellResponse, IngestProgressEvent, TaskResponse } from "../types";

type IngestProgressState = {
  totalFiles: number;
  filesProcessed: number;
  chunksIndexed: number;
  currentFile: string | null;
  detail: string | null;
  mode: "stream" | "sync";
};

function buildTaskContext(
  cellLabel: string,
  returnPath: string,
  taskId: number,
  huCode: string,
  enunciado: string,
  chatConversationId: string | null | undefined,
  resumeWorkspaceChat: boolean,
) {
  return {
    taskId,
    chatConversationId: chatConversationId ?? undefined,
    huCode,
    enunciado,
    cellLabel,
    returnPath,
    resumeWorkspaceChat,
  };
}

export function SupportCellTasksPage() {
  const navigate = useNavigate();
  const { cellId: cellIdParam } = useParams<{ cellId: string }>();
  const cellId = cellIdParam ? Number(cellIdParam) : NaN;

  const [cellLabel, setCellLabel] = useState("");
  const [repos, setRepos] = useState<CellRepoResponse[]>([]);
  const [tasks, setTasks] = useState<TaskResponse[]>([]);
  const [repoId, setRepoId] = useState<number | "">("");
  const [huCode, setHuCode] = useState("");
  const [enunciado, setEnunciado] = useState("");

  const [loadErr, setLoadErr] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [indexing, setIndexing] = useState(false);
  const [ingestErr, setIngestErr] = useState<string | null>(null);
  const [ingestProgress, setIngestProgress] = useState<IngestProgressState | null>(null);
  const [continuingId, setContinuingId] = useState<number | null>(null);

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
    if (!Number.isFinite(cellId) || cellId <= 0) {
      navigate("/support/cells", { replace: true });
    }
  }, [navigate, cellId]);

  useEffect(() => {
    if (!Number.isFinite(cellId) || cellId <= 0) return;
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

  function applyIngestEvent(ev: IngestProgressEvent) {
    if (ev.phase === "START" && ev.totalFiles != null) {
      setIngestProgress({
        totalFiles: ev.totalFiles,
        filesProcessed: 0,
        chunksIndexed: 0,
        currentFile: null,
        detail: null,
        mode: "stream",
      });
    }
    if (ev.phase === "FILE" || ev.phase === "PROGRESS") {
      setIngestProgress((prev) => ({
        totalFiles: ev.totalFiles ?? prev?.totalFiles ?? 0,
        filesProcessed: ev.filesProcessed ?? 0,
        chunksIndexed: ev.chunksIndexed ?? 0,
        currentFile: ev.currentFile ?? null,
        detail: ev.detail ?? null,
        mode: "stream",
      }));
    }
  }

  async function runConnectAndWorkspace(
    cont: Awaited<ReturnType<typeof continueTask>>,
    taskCtx: ReturnType<typeof buildTaskContext>,
    /** Solo en tarea nueva: primer mensaje automático al modelo. Al continuar una tarea no se reenvía el prompt. */
    includeInitialChatPrompt: boolean,
  ) {
    const ns = cont.vectorNamespaceHint?.trim();
    const connectBody = {
      ...cont.gitConnect,
      ...(ns ? { vectorNamespace: ns } : {}),
    };
    const res = await connectGit(connectBody);
    saveGitConnectRequest(connectBody);
    const navState: Record<string, unknown> = {
      connect: res,
      taskCellRepoId: cont.cellRepoId,
      taskContext: taskCtx,
    };
    if (includeInitialChatPrompt && cont.initialChatPrompt?.trim()) {
      navState.initialChatPrompt = cont.initialChatPrompt;
    }
    if (!ns) {
      const r = await vectorIngestStream(applyIngestEvent);
      navigate("/app", {
        state: {
          ...navState,
          initialIngest: r,
        },
      });
      return;
    }
    navigate("/app", {
      state: {
        ...navState,
        initialIngest: {
          filesProcessed: 0,
          chunksIndexed: 0,
          namespace: ns,
          skipped: [],
        },
      },
    });
  }

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
      const created = await createTask({
        huCode: hu,
        cellRepoId: repoId as number,
        enunciado: en,
      });
      const cont = await continueTask(created.id);
      if (!cont.vectorNamespaceHint?.trim()) {
        setIndexing(true);
        setIngestProgress({
          totalFiles: 0,
          filesProcessed: 0,
          chunksIndexed: 0,
          currentFile: null,
          detail: null,
          mode: "stream",
        });
      }
      await runConnectAndWorkspace(
        cont,
        buildTaskContext(
          cont.cellName?.trim() || cellLabel,
          returnPath,
          created.id,
          hu,
          en,
          cont.chatConversationId ?? created.chatConversationId,
          false,
        ),
        true,
      );
    } catch (err) {
      setIngestErr(err instanceof Error ? err.message : String(err));
      setIndexing(false);
      setIngestProgress(null);
    }
  }

  async function onContinueTask(task: TaskResponse) {
    setError(null);
    setIngestErr(null);
    setContinuingId(task.id);
    try {
      const cont = await continueTask(task.id);
      if (!cont.vectorNamespaceHint?.trim()) {
        setIndexing(true);
        setIngestProgress({
          totalFiles: 0,
          filesProcessed: 0,
          chunksIndexed: 0,
          currentFile: null,
          detail: null,
          mode: "stream",
        });
      }
      await runConnectAndWorkspace(
        cont,
        buildTaskContext(
          cont.cellName?.trim() || cellLabel,
          returnPath,
          task.id,
          task.huCode,
          task.enunciado,
          cont.chatConversationId ?? task.chatConversationId,
          true,
        ),
        false,
      );
    } catch (err) {
      setIngestErr(err instanceof Error ? err.message : String(err));
      setIndexing(false);
      setIngestProgress(null);
    } finally {
      setContinuingId(null);
    }
  }

  const busy = indexing;
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

      {indexing && ingestProgress && (
        <section className="card connect-page__indexing" aria-live="polite">
          <h2 className="connect-page__indexing-title">Indexando repositorio</h2>
          <div className="ingest-progress ingest-progress--bar connect-page__ingest-box">
            <div className="ingest-progress__stats ingest-progress__stats--bar">
              {ingestProgress.totalFiles > 0 ? (
                <>
                  Archivos:{" "}
                  <strong>
                    {ingestProgress.filesProcessed} / {ingestProgress.totalFiles}
                  </strong>
                  <span className="muted"> · Chunks: {ingestProgress.chunksIndexed}</span>
                </>
              ) : (
                <span className="muted">Preparando lista…</span>
              )}
            </div>
          </div>
        </section>
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
                <span className="muted">{t.status}</span>
                <span style={{ flex: "1 1 100%", fontSize: "0.9rem" }}>{t.enunciado.slice(0, 160)}{t.enunciado.length > 160 ? "…" : ""}</span>
                <button
                  type="button"
                  className="btn primary btn--small"
                  disabled={continuingId === t.id}
                  onClick={() => onContinueTask(t)}
                >
                  {continuingId === t.id ? "Abriendo…" : "Continuar en workspace"}
                </button>
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
                const v = ev.target.value;
                setRepoId(v === "" ? "" : Number(v));
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
              placeholder="Describe el problema o la petición de soporte…"
            />
          </label>

          {error && <p className="error">{error}</p>}
          {ingestErr && <p className="error">{ingestErr}</p>}

          <button type="submit" className="btn primary">
            Crear y continuar al workspace
          </button>
        </form>
      )}
    </div>
  );
}
