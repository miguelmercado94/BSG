import { useCallback } from "react";

import {
  fetchFileContent,
  fetchTextFromPresignedUrl,
  fetchWorkAreaDraftContent,
  fetchWorkAreaS3ArtifactBody,
  type WorkAreaRequestInit,
} from "../api/client";
import type { WorkAreaDiffLine, WorkAreaFileProposal } from "../types";

type WorkAreaDiffViewerProps = {
  lines: WorkAreaDiffLine[];
  /** Texto bajo el título; por defecto explica verde/rojo. */
  caption?: string;
};

const DEFAULT_DIFF_CAPTION =
  "Una sola vista: líneas añadidas en verde y eliminadas en rojo (respecto al archivo del repositorio).";

export function WorkAreaIconDownload() {
  return (
    <svg className="work-area-panel__icon-svg" viewBox="0 0 24 24" width="18" height="18" aria-hidden>
      <path
        fill="currentColor"
        d="M19 9h-4V3H9v6H5l7 7 7-7zM5 18v2h14v-2H5z"
      />
    </svg>
  );
}

export function WorkAreaIconTrash() {
  return (
    <svg className="work-area-panel__icon-svg" viewBox="0 0 24 24" width="18" height="18" aria-hidden>
      <path
        fill="currentColor"
        d="M6 19c0 1.1.9 2 2 2h8c1.1 0 2-.9 2-2V7H6v12zM19 4h-3.5l-1-1h-5l-1 1H5v2h14V4z"
      />
    </svg>
  );
}

/** Vista previa de propuesta (diff unificado +/-); se usa en el panel central del workspace. */
export function WorkAreaDiffViewer({ lines, caption = DEFAULT_DIFF_CAPTION }: WorkAreaDiffViewerProps) {
  return (
    <div className="work-area-diff" role="region" aria-label="Diff unificado: propuesto con cambios en verde y rojo">
      <p className="work-area-diff__caption muted small">{caption}</p>
      <div className="work-area-diff__scroll">
        <div className="work-area-diff__lines">
          {lines.map((l, i) => (
            <div
              key={i}
              className={
                "work-area-diff__line work-area-diff__line--" +
                (l.kind === "added" ? "added" : l.kind === "removed" ? "removed" : "context")
              }
            >
              <span className="work-area-diff__mark" aria-hidden>
                {l.kind === "added" ? "+" : l.kind === "removed" ? "−" : " "}
              </span>
              <span className="work-area-diff__text">{l.text}</span>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

type Props = {
  proposals: WorkAreaFileProposal[];
  selectedId: string | null;
  onSelect: (id: string) => void;
  onAcceptAll: () => void | Promise<void>;
  notice: string | null;
  error: string | null;
  /** Desactiva chips mientras se indexa desde el panel principal */
  busy: boolean;
  /** Cabeceras de tarea para GET del borrador en el backend (mismo criterio que el resto del workspace). */
  downloadRequestInit?: WorkAreaRequestInit;
  /** Texto opcional: dónde persisten borradores/workarea en S3 para esta tarea. */
  persistenceHint?: string | null;
  /** Eliminar objeto listado desde S3 (borradores o workarea). */
  onDeleteS3Artifact?: (p: WorkAreaFileProposal) => void | Promise<void>;
};

/**
 * Solo lista de borradores. La vista previa y las acciones están en el visualizador principal.
 */
export function WorkAreaPanel({
  proposals,
  selectedId,
  onSelect,
  onAcceptAll,
  notice,
  error,
  busy,
  downloadRequestInit,
  persistenceHint,
  onDeleteS3Artifact,
}: Props) {
  /** Incluye borradores virtuales (solo JSON) sin `draftRelativePath`; excluye filas solo-S3 del GET /s3-artifacts. */
  const pendingDrafts = proposals.filter((p) => !p.acceptedRelativePath && !p.artifactViewOnly);

  /** Si hay cualquier archivo en el área de trabajo, se ocultan los párrafos largos para ganar espacio al listado. */
  const hideIntroHints = proposals.length > 0;

  const downloadProposal = useCallback(
    async (p: WorkAreaFileProposal) => {
      try {
        let text = p.content != null && p.content.trim().length > 0 ? p.content : "";
        if (!text && p.draftRelativePath) {
          const r = await fetchWorkAreaDraftContent(p.draftRelativePath, downloadRequestInit);
          text = r.content;
        }
        if (!text && p.s3Bucket?.trim() && p.s3ObjectKey?.trim()) {
          text = await fetchWorkAreaS3ArtifactBody(p.s3Bucket, p.s3ObjectKey, downloadRequestInit);
        }
        if (!text && p.s3PresignedUrl) {
          text = await fetchTextFromPresignedUrl(p.s3PresignedUrl);
        }
        if (!text?.trim() && p.acceptedRelativePath) {
          const r = await fetchFileContent(p.acceptedRelativePath);
          text = r.content;
        }
        if (!text?.trim()) {
          window.alert("No hay contenido disponible para descargar todavía.");
          return;
        }
        const name = p.fileName?.trim() || "borrador.txt";
        const blob = new Blob([text], { type: "text/plain;charset=utf-8" });
        const url = URL.createObjectURL(blob);
        const a = document.createElement("a");
        a.href = url;
        a.download = name;
        a.rel = "noopener";
        document.body.appendChild(a);
        a.click();
        a.remove();
        URL.revokeObjectURL(url);
      } catch (e) {
        window.alert(e instanceof Error ? e.message : String(e));
      }
    },
    [downloadRequestInit],
  );

  /** Cualquier fila con objeto S3 direccionable (descarga vía backend / eliminación). */
  const s3ArtifactRow = (p: WorkAreaFileProposal) =>
    Boolean(p.s3Bucket?.trim() && p.s3ObjectKey?.trim());

  return (
    <div className="work-area-panel">
      <div className="work-area-panel__intro">
        <h2>Área de trabajo</h2>
        {!hideIntroHints ? (
          <>
            <p className="muted small work-area-panel__hint">
              Tras cada respuesta del chat se lista lo publicado en S3 (borradores / workarea). Los nombres en amarillo
              son borradores y en azul workarea; al elegir uno se muestra el contenido desde la URL presignada. Las
              acciones de clonar/aceptar aplican solo a borradores generados en el flujo clásico (no solo-S3).
            </p>
            {persistenceHint ? (
              <p className="muted small work-area-panel__hint" role="note">
                {persistenceHint}
              </p>
            ) : null}
          </>
        ) : null}
        {error && (
          <p className="error small work-area-panel__err" role="alert">
            {error}
          </p>
        )}
        {notice && (
          <p className="work-area-panel__notice small" role="status">
            {notice}
          </p>
        )}
      </div>

      <div className="work-area-panel__files-rack" aria-label="Lista de archivos nuevos">
        <div className="work-area-panel__files-rack-head">
          <span className="work-area-panel__files-rack-label">Archivos nuevos</span>
          {proposals.length > 0 && (
            <span className="work-area-panel__files-rack-count">{proposals.length}</span>
          )}
          {pendingDrafts.length > 1 && (
            <button
              type="button"
              className="btn btn--small primary work-area-panel__accept-all"
              disabled={busy}
              onClick={() => void onAcceptAll()}
            >
              Aceptar todos
            </button>
          )}
        </div>
        {proposals.length === 0 ? (
          <p className="work-area-panel__files-rack-empty muted small">
            Sin archivos en S3 para esta tarea. Tras una respuesta del asistente, se actualizará el listado automáticamente.
          </p>
        ) : (
          <ul className="work-area-panel__chips" role="listbox" aria-label="Borradores">
            {proposals.map((p) => {
              const active = p.id === selectedId;
              const b = p.s3Bucket?.toLowerCase() ?? "";
              const bucketChip =
                p.artifactViewOnly && p.s3Bucket
                  ? b.includes("borrador")
                    ? " work-area-panel__chip--bucket-borradores"
                    : b.includes("workarea")
                      ? " work-area-panel__chip--bucket-workarea"
                      : " work-area-panel__chip--draft"
                  : "";
              const stateChip =
                p.artifactViewOnly && bucketChip
                  ? ""
                  : p.vectorIndexed
                    ? " work-area-panel__chip--indexed"
                    : p.acceptedRelativePath
                      ? " work-area-panel__chip--saved"
                      : " work-area-panel__chip--draft";
              return (
                <li key={p.id} className="work-area-panel__chip-row">
                  <button
                    type="button"
                    role="option"
                    aria-selected={active}
                    disabled={busy}
                    className={
                      "work-area-panel__chip" +
                      (bucketChip || stateChip) +
                      (active ? " work-area-panel__chip--active" : "")
                    }
                    onClick={() => onSelect(p.id)}
                    title={
                      p.artifactViewOnly && p.s3Bucket
                        ? `${p.s3Bucket} · ${p.s3ObjectKey ?? ""}`
                        : p.vectorIndexed
                          ? `Indexado en RAG${p.lastIndexedChunks != null ? ` (${p.lastIndexedChunks} fragmentos)` : ""}`
                          : p.acceptedRelativePath
                            ? "Guardado en el clon; pendiente de indexar para RAG"
                            : "Borrador pendiente"
                    }
                  >
                    {!p.artifactViewOnly && (p.vectorIndexed ? "◉ " : p.acceptedRelativePath ? "✓ " : "")}
                    {p.fileName}
                  </button>
                  {s3ArtifactRow(p) ? (
                    <div
                      className="work-area-panel__chip-actions"
                      onClick={(e) => e.stopPropagation()}
                      onKeyDown={(e) => e.stopPropagation()}
                      role="group"
                      aria-label={`Acciones: ${p.fileName}`}
                    >
                      <button
                        type="button"
                        className="work-area-panel__icon-btn"
                        disabled={busy}
                        title="Descargar"
                        aria-label={`Descargar ${p.fileName}`}
                        onClick={() => void downloadProposal(p)}
                      >
                        <WorkAreaIconDownload />
                      </button>
                      {onDeleteS3Artifact ? (
                        <button
                          type="button"
                          className="work-area-panel__icon-btn work-area-panel__icon-btn--danger"
                          disabled={busy}
                          title="Eliminar de S3"
                          aria-label={`Eliminar ${p.fileName} de S3`}
                          onClick={() => void onDeleteS3Artifact(p)}
                        >
                          <WorkAreaIconTrash />
                        </button>
                      ) : null}
                    </div>
                  ) : null}
                </li>
              );
            })}
          </ul>
        )}
      </div>
    </div>
  );
}
