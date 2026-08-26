import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { fetchAllTags, createTag, updateTag, deleteTag, addTagTool, removeTagTool, getUserId, isSupportRole } from "../api/client";
import type { TagDetail } from "../api/client";

export function AdminTagsPage() {
  const navigate = useNavigate();
  const [tags, setTags] = useState<TagDetail[]>([]);
  const [loading, setLoading] = useState(true);
  const [err, setErr] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  // Create form state
  const [showCreate, setShowCreate] = useState(false);
  const [newTagName, setNewTagName] = useState("");
  const [newTagDesc, setNewTagDesc] = useState("");
  const [newToolUrl, setNewToolUrl] = useState("");
  const [newToolCtx, setNewToolCtx] = useState("");
  const [newTools, setNewTools] = useState<Array<{ urlTool: string; contextoUrl: string }>>([]);

  // Expanded tag editing
  const [expandedTag, setExpandedTag] = useState<string | null>(null);
  const [editDesc, setEditDesc] = useState("");
  const [editEnabled, setEditEnabled] = useState(true);
  const [addToolUrl, setAddToolUrl] = useState("");
  const [addToolCtx, setAddToolCtx] = useState("");

  // Delete confirmation
  const [deleteConfirm, setDeleteConfirm] = useState<string | null>(null);

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
      const list = await fetchAllTags();
      setTags(list);
    } catch (e) {
      setErr(e instanceof Error ? e.message : String(e));
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    void reload();
  }, []);

  function expandTag(tag: TagDetail) {
    if (expandedTag === tag.tag) {
      setExpandedTag(null);
      return;
    }
    setExpandedTag(tag.tag);
    setEditDesc(tag.descripcionTag ?? "");
    setEditEnabled(tag.habilitado);
    setAddToolUrl("");
    setAddToolCtx("");
  }

  async function handleCreate() {
    if (!newTagName.trim()) {
      setErr("El nombre del tag es obligatorio.");
      return;
    }
    setBusy(true);
    setErr(null);
    try {
      // Si hay una URL escrita pero no se presionó +, incluirla automáticamente
      const toolsToSend = [...newTools];
      if (newToolUrl.trim()) {
        toolsToSend.push({ urlTool: newToolUrl.trim(), contextoUrl: newToolCtx.trim() });
      }
      await createTag({
        tag: newTagName.trim(),
        descripcionTag: newTagDesc.trim() || undefined,
        herramientasUrls: toolsToSend.length > 0 ? toolsToSend : undefined,
      });
      setNewTagName("");
      setNewTagDesc("");
      setNewTools([]);
      setNewToolUrl("");
      setNewToolCtx("");
      setShowCreate(false);
      await reload();
    } catch (e) {
      setErr(e instanceof Error ? e.message : String(e));
    } finally {
      setBusy(false);
    }
  }

  async function handleSaveTag(tagName: string) {
    setBusy(true);
    setErr(null);
    try {
      await updateTag(tagName, {
        descripcionTag: editDesc.trim() || undefined,
        habilitado: editEnabled,
      });
      await reload();
    } catch (e) {
      setErr(e instanceof Error ? e.message : String(e));
    } finally {
      setBusy(false);
    }
  }

  async function handleDeleteTag(tagName: string) {
    setBusy(true);
    setErr(null);
    try {
      await deleteTag(tagName);
      setDeleteConfirm(null);
      setExpandedTag(null);
      await reload();
    } catch (e) {
      setErr(e instanceof Error ? e.message : String(e));
    } finally {
      setBusy(false);
    }
  }

  async function handleAddTool(tagName: string) {
    if (!addToolUrl.trim()) {
      setErr("La URL de la herramienta es obligatoria.");
      return;
    }
    setBusy(true);
    setErr(null);
    try {
      await addTagTool(tagName, addToolUrl.trim(), addToolCtx.trim());
      setAddToolUrl("");
      setAddToolCtx("");
      await reload();
    } catch (e) {
      setErr(e instanceof Error ? e.message : String(e));
    } finally {
      setBusy(false);
    }
  }

  async function handleRemoveTool(tagName: string, urlTool: string) {
    setBusy(true);
    setErr(null);
    try {
      await removeTagTool(tagName, urlTool);
      await reload();
    } catch (e) {
      setErr(e instanceof Error ? e.message : String(e));
    } finally {
      setBusy(false);
    }
  }

  function addNewToolToList() {
    if (!newToolUrl.trim()) return;
    setNewTools((prev) => [...prev, { urlTool: newToolUrl.trim(), contextoUrl: newToolCtx.trim() }]);
    setNewToolUrl("");
    setNewToolCtx("");
  }

  return (
    <div className="page connect-page admin-cells-list">
      <button
        type="button"
        className="admin-back-btn"
        onClick={() => navigate("/admin/cells")}
        aria-label="Volver"
        title="Volver"
      >
        ←
      </button>

      <header className="page__header admin-cells-list__header">
        <h1>Configurar Tags</h1>
        <p className="muted">
          Gestiona los tags disponibles y sus herramientas URL asociadas.
        </p>
      </header>

      {err && (
        <p className="muted small" role="alert" style={{ color: "#f28b82" }}>
          {err}
        </p>
      )}

      {/* Create tag section */}
      <section className="card" style={{ marginBottom: "1rem" }}>
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
          <h2 className="h3">Tags existentes</h2>
          <button
            type="button"
            className="btn primary"
            onClick={() => setShowCreate(!showCreate)}
            style={{ fontSize: "0.85rem" }}
          >
            {showCreate ? "Cancelar" : "Crear tag"}
          </button>
        </div>

        {showCreate && (
          <div style={{ marginTop: "1rem", padding: "1rem", background: "rgba(255,255,255,0.03)", borderRadius: "8px", border: "1px solid rgba(255,255,255,0.08)" }}>
            <div className="field" style={{ marginBottom: "0.75rem" }}>
              <label className="small">Nombre del tag</label>
              <input
                type="text"
                value={newTagName}
                onChange={(e) => setNewTagName(e.target.value)}
                placeholder="Ej: backend-java"
                style={{ width: "100%" }}
              />
            </div>
            <div className="field" style={{ marginBottom: "0.75rem" }}>
              <label className="small">Descripción (opcional)</label>
              <input
                type="text"
                value={newTagDesc}
                onChange={(e) => setNewTagDesc(e.target.value)}
                placeholder="Descripción del tag"
                style={{ width: "100%" }}
              />
            </div>

            {/* Initial tools */}
            {newTools.length > 0 && (
              <div style={{ marginBottom: "0.75rem" }}>
                <label className="small">Herramientas agregadas:</label>
                <ul style={{ listStyle: "none", padding: 0, margin: "0.25rem 0" }}>
                  {newTools.map((t, i) => (
                    <li key={i} style={{ fontSize: "0.8rem", color: "#9aa0a6", display: "flex", alignItems: "center", gap: "0.5rem", marginBottom: "0.25rem" }}>
                      <span style={{ flex: 1 }}>{t.urlTool} — {t.contextoUrl || "(sin contexto)"}</span>
                      <button
                        type="button"
                        className="admin-icon-btn admin-icon-btn--danger"
                        onClick={() => setNewTools((prev) => prev.filter((_, idx) => idx !== i))}
                        style={{ fontSize: "0.8rem" }}
                      >
                        ×
                      </button>
                    </li>
                  ))}
                </ul>
              </div>
            )}

            <div style={{ display: "flex", gap: "0.5rem", alignItems: "flex-end", marginBottom: "0.75rem" }}>
              <div style={{ flex: 2 }}>
                <label className="small">URL herramienta (opcional)</label>
                <input
                  type="text"
                  value={newToolUrl}
                  onChange={(e) => setNewToolUrl(e.target.value)}
                  placeholder="https://..."
                  style={{ width: "100%" }}
                />
              </div>
              <div style={{ flex: 2 }}>
                <label className="small">Contexto</label>
                <input
                  type="text"
                  value={newToolCtx}
                  onChange={(e) => setNewToolCtx(e.target.value)}
                  placeholder="Contexto de uso"
                  style={{ width: "100%" }}
                />
              </div>
              <button type="button" className="btn" onClick={addNewToolToList} style={{ fontSize: "0.8rem" }}>
                +
              </button>
            </div>

            <button
              type="button"
              className="btn primary"
              disabled={busy || !newTagName.trim()}
              onClick={() => void handleCreate()}
            >
              {busy ? "Creando…" : "Crear tag"}
            </button>
          </div>
        )}

        {/* Tags list */}
        {loading ? (
          <p className="muted small" role="status" style={{ marginTop: "1rem" }}>
            Cargando…
          </p>
        ) : tags.length === 0 ? (
          <p className="muted small" style={{ marginTop: "1rem" }}>No hay tags registrados.</p>
        ) : (
          <ul className="admin-cells-list__ul" style={{ marginTop: "1rem" }}>
            {tags.map((tag) => (
              <li key={tag.tag} style={{ borderBottom: "1px solid rgba(255,255,255,0.06)", paddingBottom: "0.5rem", marginBottom: "0.5rem" }}>
                <div
                  className="admin-cells-list__row"
                  style={{ cursor: "pointer" }}
                  onClick={() => expandTag(tag)}
                >
                  <span className="admin-cells-list__name" style={{ flex: 1 }}>
                    {tag.tag}
                    <span className="muted small" style={{ fontWeight: "normal", marginLeft: "0.75rem" }}>
                      {tag.descripcionTag || "—"}
                    </span>
                  </span>
                  <span className="muted small" style={{ marginRight: "0.75rem" }}>
                    {tag.habilitado ? "✓" : "✗"} · {tag.herramientasUrls.length} tool{tag.herramientasUrls.length !== 1 ? "s" : ""}
                  </span>
                  <span style={{ fontSize: "0.8rem", color: "#9aa0a6" }}>
                    {expandedTag === tag.tag ? "▲" : "▼"}
                  </span>
                </div>

                {/* Expanded edit section */}
                {expandedTag === tag.tag && (
                  <div style={{ marginTop: "0.75rem", padding: "0.75rem", background: "rgba(255,255,255,0.03)", borderRadius: "8px", border: "1px solid rgba(255,255,255,0.08)" }}>
                    <div className="field" style={{ marginBottom: "0.75rem" }}>
                      <label className="small">Descripción</label>
                      <input
                        type="text"
                        value={editDesc}
                        onChange={(e) => setEditDesc(e.target.value)}
                        placeholder="Descripción del tag"
                        style={{ width: "100%" }}
                      />
                    </div>

                    <div className="field" style={{ marginBottom: "0.75rem", display: "flex", alignItems: "center", gap: "0.5rem" }}>
                      <label className="small" style={{ marginBottom: 0 }}>Habilitado</label>
                      <input
                        type="checkbox"
                        checked={editEnabled}
                        onChange={(e) => setEditEnabled(e.target.checked)}
                      />
                    </div>

                    {/* Tools list */}
                    <div style={{ marginBottom: "0.75rem" }}>
                      <label className="small">Herramientas URL ({tag.herramientasUrls.length})</label>
                      {tag.herramientasUrls.length === 0 ? (
                        <p className="muted small" style={{ margin: "0.25rem 0" }}>Sin herramientas.</p>
                      ) : (
                        <ul style={{ listStyle: "none", padding: 0, margin: "0.25rem 0" }}>
                          {tag.herramientasUrls.map((tool, i) => (
                            <li key={i} style={{ fontSize: "0.8rem", color: "#9aa0a6", display: "flex", alignItems: "center", gap: "0.5rem", marginBottom: "0.25rem" }}>
                              <span style={{ flex: 1, wordBreak: "break-all" }}>
                                {tool.urlTool} — <em>{tool.contextoUrl || "(sin contexto)"}</em>
                              </span>
                              <button
                                type="button"
                                className="admin-icon-btn admin-icon-btn--danger"
                                disabled={busy}
                                onClick={() => void handleRemoveTool(tag.tag, tool.urlTool)}
                                title="Eliminar herramienta"
                                style={{ fontSize: "0.8rem" }}
                              >
                                ×
                              </button>
                            </li>
                          ))}
                        </ul>
                      )}
                    </div>

                    {/* Add tool form */}
                    <div style={{ display: "flex", gap: "0.5rem", alignItems: "flex-end", marginBottom: "0.75rem" }}>
                      <div style={{ flex: 2 }}>
                        <label className="small">Agregar herramienta — URL</label>
                        <input
                          type="text"
                          value={addToolUrl}
                          onChange={(e) => setAddToolUrl(e.target.value)}
                          placeholder="https://..."
                          style={{ width: "100%" }}
                        />
                      </div>
                      <div style={{ flex: 2 }}>
                        <label className="small">Contexto</label>
                        <input
                          type="text"
                          value={addToolCtx}
                          onChange={(e) => setAddToolCtx(e.target.value)}
                          placeholder="Contexto de uso"
                          style={{ width: "100%" }}
                        />
                      </div>
                      <button
                        type="button"
                        className="btn"
                        disabled={busy || !addToolUrl.trim()}
                        onClick={() => void handleAddTool(tag.tag)}
                        style={{ fontSize: "0.8rem" }}
                      >
                        Agregar
                      </button>
                    </div>

                    {/* Actions */}
                    <div style={{ display: "flex", gap: "0.5rem", alignItems: "center" }}>
                      <button
                        type="button"
                        className="btn primary"
                        disabled={busy}
                        onClick={() => void handleSaveTag(tag.tag)}
                      >
                        {busy ? "Guardando…" : "Guardar cambios"}
                      </button>
                      {deleteConfirm === tag.tag ? (
                        <>
                          <span className="muted small">¿Confirmar eliminación?</span>
                          <button
                            type="button"
                            className="btn"
                            style={{ color: "#f28b82", borderColor: "#f28b82" }}
                            disabled={busy}
                            onClick={() => void handleDeleteTag(tag.tag)}
                          >
                            Sí, eliminar
                          </button>
                          <button
                            type="button"
                            className="btn"
                            onClick={() => setDeleteConfirm(null)}
                          >
                            Cancelar
                          </button>
                        </>
                      ) : (
                        <button
                          type="button"
                          className="btn"
                          style={{ color: "#f28b82", borderColor: "#f28b82" }}
                          disabled={busy}
                          onClick={() => setDeleteConfirm(tag.tag)}
                        >
                          Eliminar tag
                        </button>
                      )}
                    </div>
                  </div>
                )}
              </li>
            ))}
          </ul>
        )}
      </section>
    </div>
  );
}
