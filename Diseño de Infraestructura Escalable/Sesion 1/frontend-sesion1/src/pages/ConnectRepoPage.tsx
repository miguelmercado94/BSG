import { FormEvent, useEffect, useState } from "react";
import { useLocation, useNavigate } from "react-router-dom";
import { connectGit, fetchTags, getUserId } from "../api/client";
import type { GitConnectionMode } from "../types";
import { TagDiamondPicker } from "../components/TagDiamondPicker";

type LocationState = { vcs?: "GIT" };

export function ConnectRepoPage() {
  const navigate = useNavigate();
  const location = useLocation();
  const vcs = (location.state as LocationState | undefined)?.vcs;

  const [mode, setMode] = useState<GitConnectionMode>("HTTPS_PUBLIC");
  const [repositoryUrl, setRepositoryUrl] = useState("");
  const [username, setUsername] = useState("");
  const [token, setToken] = useState("");
  const [localPath, setLocalPath] = useState("");

  const [availableTags, setAvailableTags] = useState<string[]>([]);
  const [selectedTags, setSelectedTags] = useState<string[]>([]);
  const [tagsErr, setTagsErr] = useState<string | null>(null);

  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    if (!getUserId().trim()) {
      navigate("/", { replace: true });
      return;
    }
    if (vcs !== "GIT") {
      navigate("/repo-type", { replace: true });
    }
  }, [navigate, vcs]);

  useEffect(() => {
    let cancelled = false;
    (async () => {
      try {
        const t = await fetchTags();
        if (!cancelled) {
          setAvailableTags(t.tags);
          setTagsErr(null);
        }
      } catch (e) {
        if (!cancelled) {
          setTagsErr(e instanceof Error ? e.message : String(e));
        }
      }
    })();
    return () => {
      cancelled = true;
    };
  }, []);

  function toggleTag(tag: string) {
    setSelectedTags((prev) =>
      prev.includes(tag) ? prev.filter((x) => x !== tag) : [...prev, tag],
    );
  }

  async function onSubmit(e: FormEvent) {
    e.preventDefault();
    setError(null);
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
      navigate("/app", { state: { connect: res, selectedTags } });
    } catch (err) {
      setError(err instanceof Error ? err.message : String(err));
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="page connect-page">
      <header className="page__header">
        <h1>DocViz</h1>
        <p className="muted">Contexto maestro y conexión Git.</p>
      </header>

      <section className="card context-maestro-block">
        <h2 className="context-maestro-title">CONTEXTO MAESTRO</h2>
        <p className="muted small">
          Etiquetas para futuro fine-tuning. Selecciona las que apliquen; aparecerán como rombos junto al repositorio en el workspace.
        </p>
        {tagsErr && <p className="error">{tagsErr}</p>}
        <TagDiamondPicker
          availableTags={availableTags}
          selectedTags={selectedTags}
          onToggle={toggleTag}
        />
      </section>

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

        <button type="submit" className="btn primary" disabled={loading}>
          {loading ? "Conectando…" : "Conectar"}
        </button>
      </form>
    </div>
  );
}
