import { FormEvent, useState } from "react";
import { useNavigate } from "react-router-dom";
import { connectGit, getUserId, setUserId } from "../api/client";
import type { GitConnectionMode } from "../types";

export function ConnectPage() {
  const navigate = useNavigate();
  const [user, setUser] = useState(getUserId());
  const [mode, setMode] = useState<GitConnectionMode>("HTTPS_PUBLIC");
  const [repositoryUrl, setRepositoryUrl] = useState("");
  const [username, setUsername] = useState("");
  const [token, setToken] = useState("");
  const [localPath, setLocalPath] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  async function onSubmit(e: FormEvent) {
    e.preventDefault();
    setError(null);
    if (!user.trim()) {
      setError("Indica un identificador de usuario (se envía en el header X-DocViz-User).");
      return;
    }
    setUserId(user.trim());
    setLoading(true);
    try {
      const body = {
        mode,
        repositoryUrl: mode === "LOCAL" ? undefined : repositoryUrl.trim() || undefined,
        username: mode === "HTTPS_AUTH" ? username.trim() || undefined : undefined,
        token: mode === "HTTPS_AUTH" ? token || undefined : undefined,
        localPath: mode === "LOCAL" ? localPath.trim() || undefined : undefined,
      };
      const res = await connectGit(body);
      navigate("/app", { state: { connect: res } });
    } catch (err) {
      setError(err instanceof Error ? err.message : String(err));
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="page connect-page">
      <header className="page__header">
        <h1>DocViz — Git + Pinecone + RAG</h1>
        <p className="muted">
          Conecta un repositorio (clone metadatos), explora archivos, indexa en Pinecone y pregunta con OpenAI.
        </p>
      </header>

      <form className="card" onSubmit={onSubmit}>
        <label className="field">
          <span>Usuario (sesión)</span>
          <input
            value={user}
            onChange={(e) => setUser(e.target.value)}
            placeholder="ej. alumno-01"
            autoComplete="off"
          />
        </label>

        <label className="field">
          <span>Modo</span>
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

        <button type="submit" className="btn primary" disabled={loading}>
          {loading ? "Conectando…" : "Conectar"}
        </button>
      </form>
    </div>
  );
}
