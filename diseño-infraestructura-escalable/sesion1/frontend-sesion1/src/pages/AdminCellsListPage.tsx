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
    null | { cellId: number; name: string; taskCount: number | null; loading: boolean }
  >(null);

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

  async function openDeleteModal(id: number, name: string) {
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
        {hasCells && (
          <button
            type="button"
            className="admin-cells-list__fab-small"
            onClick={() => navigate("/admin/cells/new")}
            title="Agrega nueva célula"
            aria-label="Agrega nueva célula"
          >
            +
          </button>
        )}
      </header>

      {err && (
        <p className="muted small" role="alert">
          {err}
        </p>
      )}

      <section className="card admin-cells-list__card">
        <h2 className="h3">Células existentes</h2>
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
                <span className="admin-cells-list__name">{c.name}</span>
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
