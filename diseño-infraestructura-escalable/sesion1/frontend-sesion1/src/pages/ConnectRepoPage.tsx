import { FormEvent, useEffect, useState } from "react";
import { useLocation, useNavigate } from "react-router-dom";
import { connectGit, getUserId, isSupportRole, vectorIngestStream } from "../api/client";
import { saveGitConnectRequest } from "../lib/docvizGitSession";
import type { ConnectResponse, GitConnectionMode, IngestProgressEvent } from "../types";

type LocationState = { vcs?: "GIT"; fromAdmin?: boolean };

type IngestProgressState = {
  totalFiles: number;
  filesProcessed: number;
  chunksIndexed: number;
  currentFile: string | null;
  detail: string | null;
  mode: "stream" | "sync";
};

export function ConnectRepoPage() {
  const navigate = useNavigate();
  const location = useLocation();
  const locState = location.state as LocationState | undefined;
  const vcs = locState?.vcs;
  const fromAdmin = locState?.fromAdmin === true;

  const [mode, setMode] = useState<GitConnectionMode>("HTTPS_PUBLIC");
  const [repositoryUrl, setRepositoryUrl] = useState("");
  const [username, setUsername] = useState("");
  const [token, setToken] = useState("");
  const [localPath, setLocalPath] = useState("");

  const [error, setError] = useState<string | null>(null);
  /** Conexión Git en curso */
  const [connecting, setConnecting] = useState(false);
  /** Indexación vectorial tras conectar (misma pantalla) */
  const [indexing, setIndexing] = useState(false);
  const [ingestErr, setIngestErr] = useState<string | null>(null);
  const [ingestProgress, setIngestProgress] = useState<IngestProgressState | null>(null);
  /** Sesión ya conectada; sirve para reintentar solo la ingesta */
  const [pendingConnect, setPendingConnect] = useState<ConnectResponse | null>(null);

  useEffect(() => {
    if (!getUserId().trim()) {
      navigate("/", { replace: true });
      return;
    }
    if (isSupportRole()) {
      navigate("/support/cells", { replace: true });
      return;
    }
    if (vcs !== "GIT") {
      navigate("/admin/cells", { replace: true });
    }
  }, [navigate, vcs]);

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

  async function runIngestAndGo(res: ConnectResponse) {
    setError(null);
    setIngestErr(null);
    setIndexing(true);
    setIngestProgress({
      totalFiles: 0,
      filesProcessed: 0,
      chunksIndexed: 0,
      currentFile: null,
      detail: null,
      mode: "stream",
    });
    try {
      const r = await vectorIngestStream(applyIngestEvent);
      navigate("/app", {
        state: {
          connect: res,
          initialIngest: r,
        },
      });
    } catch (e) {
      setIngestErr(e instanceof Error ? e.message : String(e));
      setPendingConnect(res);
      setIndexing(false);
      setIngestProgress(null);
    }
  }

  async function retryIngestOnly() {
    if (!pendingConnect) return;
    setError(null);
    setIngestErr(null);
    await runIngestAndGo(pendingConnect);
  }

  async function onSubmit(e: FormEvent) {
    e.preventDefault();
    setError(null);
    setConnecting(true);
    try {
      const body = {
        mode,
        repositoryUrl: mode === "LOCAL" ? undefined : repositoryUrl.trim() || undefined,
        username: mode === "HTTPS_AUTH" ? username.trim() || undefined : undefined,
        token: mode === "HTTPS_AUTH" ? token || undefined : undefined,
        localPath: mode === "LOCAL" ? localPath.trim() || undefined : undefined,
      };
      const res = await connectGit(body);
      saveGitConnectRequest(body);
      await runIngestAndGo(res);
    } catch (err) {
      setError(err instanceof Error ? err.message : String(err));
    } finally {
      setConnecting(false);
    }
  }

  const busy = connecting || indexing;

  return (
    <div className="page connect-page">
      <header className="page__header">
        <h1>DocViz</h1>
        <p className="muted">Contexto maestro y conexión Git.</p>
      </header>

      {fromAdmin && (
        <p className="muted small" style={{ marginBottom: "0.75rem" }}>
          <button type="button" className="btn" onClick={() => navigate("/admin/cells")}>
            ← Volver a células
          </button>
        </p>
      )}

      {indexing && ingestProgress && (
        <section className="card connect-page__indexing" aria-live="polite">
          <div className="connect-page__indexing-visual" role="status" aria-label="Indexando en curso">
            <svg
              className="connect-page__gear"
              xmlns="http://www.w3.org/2000/svg"
              viewBox="0 0 24 24"
              fill="currentColor"
              aria-hidden="true"
            >
              <path d="M19.14 12.94c.04-.31.06-.63.06-.94 0-.32-.02-.64-.07-.94l2.03-1.58c.18-.14.23-.41.12-.61l-1.92-3.32c-.12-.22-.37-.29-.59-.22l-2.39.96c-.5-.38-1.03-.7-1.62-.94l-.36-2.54c-.04-.24-.24-.41-.48-.41h-3.84c-.24 0-.43.17-.47.41l-.36 2.54c-.59.24-1.13.57-1.62.94l-2.39-.96c-.22-.08-.47 0-.59.22L2.74 8.87c-.12.21-.08.47.12.61l2.03 1.58c-.05.3-.09.63-.09.94s.02.64.07.94l-2.03 1.58c-.18.14-.23.41-.12.61l1.92 3.32c.12.22.37.29.59.22l2.39-.96c.5.38 1.03.7 1.62.94l.36 2.54c.05.24.24.41.48.41h3.84c.24 0 .44-.17.47-.41l.36-2.54c.59-.24 1.13-.56 1.62-.94l2.39.96c.22.08.47 0 .59-.22l1.92-3.32c.12-.22.07-.47-.12-.61l-2.01-1.58zM12 15.6c-1.98 0-3.6-1.62-3.6-3.6s1.62-3.6 3.6-3.6 3.6 1.62 3.6 3.6-1.62 3.6-3.6 3.6z" />
            </svg>
          </div>
          <h2 className="connect-page__indexing-title">Indexando repositorio</h2>
          <p className="muted small connect-page__indexing-desc">
            Se generan embeddings y se guardan en pgvector. Al terminar pasarás al workspace.
          </p>
          <div className="ingest-progress ingest-progress--bar connect-page__ingest-box">
            <p className="ingest-progress__lead ingest-progress__lead--bar small muted">
              Indexando → pgvector…
            </p>
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
            {ingestProgress.detail && (
              <div className="ingest-progress__detail ingest-progress__detail--bar small muted">
                {ingestProgress.detail}
              </div>
            )}
            {ingestProgress.currentFile && (
              <div
                className="ingest-progress__file ingest-progress__file--bar small muted"
                title={ingestProgress.currentFile}
              >
                {ingestProgress.currentFile}
              </div>
            )}
            <div
              className={
                "ingest-progress__track ingest-progress__track--bar" +
                (ingestProgress.totalFiles === 0 ? " ingest-progress__track--indeterminate" : "")
              }
            >
              <div
                className="ingest-progress__fill"
                style={{
                  width:
                    ingestProgress.totalFiles > 0
                      ? `${Math.min(
                          100,
                          (ingestProgress.filesProcessed / ingestProgress.totalFiles) * 100,
                        )}%`
                      : "30%",
                }}
              />
            </div>
          </div>
        </section>
      )}

      {ingestErr && pendingConnect && (
        <section className="card connect-page__ingest-error">
          <p className="error" role="alert">
            {ingestErr}
          </p>
          <p className="muted small">La conexión Git ya está activa. Puedes reintentar solo la indexación.</p>
          <button type="button" className="btn primary" onClick={() => void retryIngestOnly()}>
            Reintentar indexación
          </button>
        </section>
      )}

      {!indexing && (
        <>
          <form className="card" onSubmit={onSubmit}>
            <label className="field">
              <span>Modo Git</span>
              <select value={mode} onChange={(e) => setMode(e.target.value as GitConnectionMode)}>
                <option value="HTTPS_PUBLIC">HTTPS público</option>
                <option value="HTTPS_AUTH">HTTPS con token</option>
                <option value="LOCAL">Ruta local</option>
              </select>
            </label>

            {mode !== "LOCAL" && (
              <label className="field">
                <span>URL del repositorio</span>
                <input
                  value={repositoryUrl}
                  onChange={(e) => setRepositoryUrl(e.target.value)}
                  placeholder="https://github.com/org/repo.git"
                />
              </label>
            )}

            {mode === "HTTPS_AUTH" && (
              <>
                <label className="field">
                  <span>Usuario Git (opcional)</span>
                  <input value={username} onChange={(e) => setUsername(e.target.value)} />
                </label>
                <label className="field">
                  <span>Token / contraseña</span>
                  <input type="password" value={token} onChange={(e) => setToken(e.target.value)} />
                </label>
              </>
            )}

            {mode === "LOCAL" && (
              <label className="field">
                <span>Ruta absoluta del repo</span>
                <input
                  value={localPath}
                  onChange={(e) => setLocalPath(e.target.value)}
                  placeholder="C:\ruta\al\repo"
                />
              </label>
            )}

            {error && <p className="error">{error}</p>}

            <button type="submit" className="btn primary" disabled={busy}>
              {connecting ? "Conectando…" : "Conectar"}
            </button>
          </form>
        </>
      )}
    </div>
  );
}
