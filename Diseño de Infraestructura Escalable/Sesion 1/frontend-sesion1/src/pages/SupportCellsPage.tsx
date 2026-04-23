import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { fetchCells, getUserId, isSupportRole } from "../api/client";
import type { CellResponse } from "../types";

/**
 * Soporte: elige una célula configurada por el administrador para ver tareas en esa área.
 */
export function SupportCellsPage() {
  const navigate = useNavigate();
  const [cells, setCells] = useState<CellResponse[]>([]);
  const [err, setErr] = useState<string | null>(null);
  const [cellsLoading, setCellsLoading] = useState(true);

  useEffect(() => {
    if (!getUserId().trim()) {
      navigate("/", { replace: true });
      return;
    }
    if (!isSupportRole()) {
      navigate("/admin/cells", { replace: true });
    }
  }, [navigate]);

  useEffect(() => {
    let cancelled = false;
    (async () => {
      setCellsLoading(true);
      try {
        const list = await fetchCells();
        if (!cancelled) setCells(list);
      } catch (e) {
        if (!cancelled) setErr(e instanceof Error ? e.message : String(e));
      } finally {
        if (!cancelled) setCellsLoading(false);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, []);

  return (
    <div className="page connect-page">
      <header className="page__header">
        <h1>Células</h1>
        <p className="muted">
          El administrador define las áreas y repositorios. Elige una célula para ver tus tareas y crear nuevas.
        </p>
      </header>

      {err && (
        <p className="error" role="alert">
          {err}
        </p>
      )}

      <div className="card repo-type-grid">
        {cellsLoading ? (
          <p className="muted" role="status" aria-live="polite">
            Cargando células…
          </p>
        ) : cells.length === 0 ? (
          <p className="muted">No hay células disponibles. Contacta al administrador.</p>
        ) : (
          cells.map((c) => (
            <button
              key={c.id}
              type="button"
              className="repo-type-card repo-type-card--active"
              onClick={() => navigate(`/support/cells/${c.id}/tasks`)}
            >
              <span className="repo-type-card__name">{c.name}</span>
              <span className="repo-type-card__hint muted small">
                {c.description ? c.description.slice(0, 48) : "Ver tareas"}
              </span>
            </button>
          ))
        )}
      </div>
    </div>
  );
}
