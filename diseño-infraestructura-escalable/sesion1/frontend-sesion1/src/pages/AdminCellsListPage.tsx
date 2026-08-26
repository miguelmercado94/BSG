import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { adminDeleteCell, adminFetchCellDeleteImpact, fetchCells, getUserId, isSupportRole } from "../api/client";
import type { CellResponse } from "../types";

export function AdminCellsListPage() {
  const navigate = useNavigate();
  const [cells, setCells] = useState<CellResponse[]>([]);
  const [loading, setLoading] = useState(true);
  const [err, setErr] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);
  const [deleteModal, setDeleteModal] = useState<
    null | { cellId: string; name: string; taskCount: number | null; loading: boolean }
  >(null);
  const [gearOpen, setGearOpen] = useState(false);

  useEffect(() => {
    if (!getUserId().trim()) {
      navigate("/", { replace: true });
      return;
    }
    if (isSupportRole()) {
      navigate("/support/cells", { replace: true });
    }
  }, [navigate]);

  async function reload() {
    setLoading(true);
    setErr(null);
    try {
      const list = await fetchCells();
      setCells(list);
    } catch (e) {
      setErr(e instanceof Error ? e.message : String(e));
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    void reload();
  }, []);

  async function openDeleteModal(id: string, name: string) {
    setDeleteModal({ cellId: id, name, taskCount: null, loading: true });
    setErr(null);
    try {
      const { taskCount } = await adminFetchCellDeleteImpact(id);
      setDeleteModal({ cellId: id, name, taskCount, loading: false });
    } catch (e) {
      setErr(e instanceof Error ? e.message : String(e));
      setDeleteModal(null);
    }
  }

  async function confirmDeleteCell() {
    if (!deleteModal || deleteModal.loading || deleteModal.taskCount === null) return;
    setBusy(true);
    setErr(null);
    try {
      await adminDeleteCell(deleteModal.cellId);
      setDeleteModal(null);
      await reload();
    } catch (e) {
      setErr(e instanceof Error ? e.message : String(e));
    } finally {
      setBusy(false);
    }
  }

  const hasCells = cells.length > 0;

  return (
    <div className="page connect-page admin-cells-list">
      <button
        type="button"
        className="admin-back-btn"
        onClick={() => navigate("/repo-type")}
        aria-label="Volver"
        title="Volver"
      >
        ←
      </button>

      <header className="page__header admin-cells-list__header">
        <h1>Células y repositorios</h1>
        <p className="muted">
          Gestiona células y sus repositorios de contexto. Usa <strong>+</strong> para crear una célula o edita una
          existente para añadir repos e indexarlos.
        </p>
        {/* Gear settings button (top-right of header) */}
        <div style={{ position: "absolute", top: 0, right: 0 }}>
          <button
            type="button"
            className="admin-cells-list__fab-small"
            onClick={() => setGearOpen(!gearOpen)}
            title="Configuración"
            aria-label="Configuración"
            style={{ background: "transparent", border: "none", color: "#9aa0a6", cursor: "pointer", padding: "0.25rem" }}
          >
            <svg width="20" height="20" viewBox="0 0 24 24"><path fill="currentColor" d="M19.14 12.94c.04-.3.06-.61.06-.94 0-.32-.02-.64-.07-.94l2.03-1.58a.49.49 0 0 0 .12-.61l-1.92-3.32a.488.488 0 0 0-.59-.22l-2.39.96c-.5-.38-1.03-.7-1.62-.94l-.36-2.54a.484.484 0 0 0-.48-.41h-3.84c-.24 0-.43.17-.47.41l-.36 2.54c-.59.24-1.13.57-1.62.94l-2.39-.96a.49.49 0 0 0-.59.22L2.74 8.87c-.12.21-.08.47.12.61l2.03 1.58c-.05.3-.07.62-.07.94s.02.64.07.94l-2.03 1.58a.49.49 0 0 0-.12.61l1.92 3.32c.12.22.37.29.59.22l2.39-.96c.5.38 1.03.7 1.62.94l.36 2.54c.05.24.24.41.48.41h3.84c.24 0 .44-.17.47-.41l.36-2.54c.59-.24 1.13-.56 1.62-.94l2.39.96c.22.08.47 0 .59-.22l1.92-3.32c.12-.22.07-.47-.12-.61l-2.01-1.58zM12 15.6A3.61 3.61 0 0 1 8.4 12 3.61 3.61 0 0 1 12 8.4a3.61 3.61 0 0 1 3.6 3.6 3.61 3.61 0 0 1-3.6 3.6z"/></svg>
          </button>
          {gearOpen && (
            <div
              style={{
                position: "absolute",
                top: "2rem",
                right: 0,
                background: "#2d2d30",
                border: "1px solid rgba(255,255,255,0.12)",
                borderRadius: "6px",
                boxShadow: "0 4px 12px rgba(0,0,0,0.4)",
                zIndex: 100,
                minWidth: "160px",
              }}
            >
              <button
                type="button"
                onClick={() => { setGearOpen(false); navigate("/admin/tags"); }}
                style={{
                  display: "block",
                  width: "100%",
                  textAlign: "left",
                  padding: "0.6rem 1rem",
                  background: "transparent",
                  border: "none",
                  color: "#e8eaed",
                  cursor: "pointer",
                  fontSize: "0.85rem",
                }}
                onMouseEnter={(e) => { (e.target as HTMLElement).style.background = "rgba(255,255,255,0.06)"; }}
                onMouseLeave={(e) => { (e.target as HTMLElement).style.background = "transparent"; }}
              >
                Configurar Tags
              </button>
            </div>
          )}
        </div>
      </header>

      {err && (
        <p className="muted small" role="alert">
          {err}
        </p>
      )}

      <section className="card admin-cells-list__card">
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
          <h2 className="h3">Células existentes</h2>
          {hasCells && (
            <button
              type="button"
              className="admin-cells-list__fab-small"
              onClick={() => navigate("/admin/cells/new")}
              title="Agrega nueva célula"
              aria-label="Agrega nueva célula"
              style={{ position: "static" }}
            >
              +
            </button>
          )}
        </div>
        {loading ? (
          <p className="muted small" role="status">
            Cargando…
          </p>
        ) : !hasCells ? (
          <div className="admin-cells-list__empty">
            <button
              type="button"
              className="admin-cells-list__fab-large"
              onClick={() => navigate("/admin/cells/new")}
              title="Agrega nueva célula"
              aria-label="Agrega nueva célula"
            >
              +
            </button>
          </div>
        ) : (
          <ul className="admin-cells-list__ul">
            {cells.map((c) => (
              <li key={c.id} className="admin-cells-list__row">
                <span className="admin-cells-list__name">
                  {c.name} <span className="muted small" style={{ fontWeight: "normal" }}>({c.id})</span>
                </span>
                <div className="admin-cells-list__actions">
                  <button
                    type="button"
                    className="admin-icon-btn admin-icon-btn--edit"
                    onClick={() => navigate(`/admin/cells/${c.id}/edit`)}
                    title="Editar célula"
                    aria-label="Editar"
                  >
                    ✎
                  </button>
                  <button
                    type="button"
                    className="admin-icon-btn admin-icon-btn--danger"
                    disabled={busy || deleteModal?.loading}
                    onClick={() => void openDeleteModal(c.id, c.name)}
                    title="Eliminar célula"
                    aria-label="Eliminar"
                  >
                    ×
                  </button>
                </div>
              </li>
            ))}
          </ul>
        )}
      </section>

      {deleteModal && (
        <div
          className="modal-overlay"
          role="presentation"
          onClick={() => !busy && !deleteModal.loading && setDeleteModal(null)}
        >
          <div
            className="modal-card card"
            role="dialog"
            aria-modal="true"
            aria-labelledby="admin-delete-cell-title"
            onClick={(ev) => ev.stopPropagation()}
          >
            <h2 id="admin-delete-cell-title" className="h3">
              Eliminar célula
            </h2>
            {deleteModal.loading ? (
              <p className="muted small">Calculando impacto…</p>
            ) : (
              <>
                <p>
                  Vas a eliminar la célula <strong>«{deleteModal.name}»</strong> y sus repositorios, índices y soportes
                  asociados.
                </p>
                <p className="admin-delete-impact">
                  <strong>{deleteModal.taskCount}</strong>{" "}
                  {deleteModal.taskCount === 1 ? "tarea vinculada se eliminará" : "tareas vinculadas se eliminarán"} (
                  historial HU en esta célula).
                </p>
              </>
            )}
            <div className="admin-cell-editor__modal-actions">
              <button
                type="button"
                className="btn"
                disabled={busy || deleteModal.loading}
                onClick={() => setDeleteModal(null)}
              >
                Cancelar
              </button>
              <button
                type="button"
                className="btn primary"
                disabled={busy || deleteModal.loading || deleteModal.taskCount === null}
                onClick={() => void confirmDeleteCell()}
              >
                {busy ? "Eliminando…" : "Eliminar definitivamente"}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
