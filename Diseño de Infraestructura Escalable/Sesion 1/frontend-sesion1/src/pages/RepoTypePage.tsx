import { useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { getUserId } from "../api/client";

export function RepoTypePage() {
  const navigate = useNavigate();

  useEffect(() => {
    if (!getUserId().trim()) {
      navigate("/", { replace: true });
    }
  }, [navigate]);

  function chooseGit() {
    navigate("/connect", { state: { vcs: "GIT" as const } });
  }

  return (
    <div className="page connect-page">
      <header className="page__header">
        <h1>Tipo de repositorio</h1>
        <p className="muted">Elige cómo se conectará el contexto maestro.</p>
      </header>

      <div className="card repo-type-grid">
        <button type="button" className="repo-type-card repo-type-card--active" onClick={chooseGit}>
          <span className="repo-type-card__name">Git</span>
          <span className="repo-type-card__hint">Disponible</span>
        </button>
        <button type="button" className="repo-type-card" disabled title="Próximamente">
          <span className="repo-type-card__name">SVN</span>
          <span className="repo-type-card__hint muted">Próximamente</span>
        </button>
        <button type="button" className="repo-type-card" disabled title="Próximamente">
          <span className="repo-type-card__name">Mercurial</span>
          <span className="repo-type-card__hint muted">Próximamente</span>
        </button>
      </div>

      <p className="muted small" style={{ textAlign: "center" }}>
        Solo <strong>Git</strong> está habilitado por ahora.
      </p>
    </div>
  );
}
