import { useCallback, useRef, type ChangeEvent } from "react";

import type { SupportDocument, SupportUploadUiState } from "../types";

import { normalizeMdFilename } from "../hooks/useSupportDocuments";
import { setDocvizFileMentionOnDataTransfer } from "../lib/docvizDrag";

type Props = {
  documents: SupportDocument[];
  selectedId: string | null;
  onSelect: (id: string) => void;
  onUpload: (file: File, content: string) => void;
  onDelete: (id: string) => void;
  uploadUi?: SupportUploadUiState;
  /** Rol soporte: sin subir ni eliminar .md */
  readOnly?: boolean;
};

function shortKey(key: string, max = 42): string {
  if (key.length <= max) return key;
  return key.slice(0, 18) + "…" + key.slice(-12);
}

export function SupportPanel({
  documents,
  selectedId,
  onSelect,
  onUpload,
  onDelete,
  uploadUi = { kind: "idle" },
  readOnly = false,
}: Props) {
  const inputRef = useRef<HTMLInputElement>(null);

  const busy = uploadUi.kind === "busy";

  const onPickFile = useCallback(() => {
    if (busy) return;
    inputRef.current?.click();
  }, [busy]);

  const onFileChange = useCallback(
    (e: ChangeEvent<HTMLInputElement>) => {
      const file = e.target.files?.[0];
      e.target.value = "";
      if (!file || busy) return;
      const reader = new FileReader();
      reader.onload = () => {
        const text = typeof reader.result === "string" ? reader.result : "";
        const named = new File([file], normalizeMdFilename(file.name), {
          type: file.type || "text/markdown",
        });
        onUpload(named, text);
      };
      reader.onerror = () => {
        /* ignore */
      };
      reader.readAsText(file, "UTF-8");
    },
    [onUpload, busy],
  );

  const onDeleteClick = useCallback(
    (id: string, label: string) => {
      if (!window.confirm(`¿Eliminar el soporte «${label}»? Esta acción no se puede deshacer.`)) {
        return;
      }
      onDelete(id);
    },
    [onDelete],
  );

  const phaseLabel =
    uploadUi.kind === "busy"
      ? uploadUi.phase === "s3"
        ? "Subiendo a S3 (LocalStack)…"
        : "Generando embeddings y guardando en PostgreSQL (pgvector)…"
      : "";

  return (
    <div className="support-panel">
      <p className="support-panel__infra-hint muted small" title="Misma infra que en docker-compose: LocalStack expone S3 en el puerto 4566">
        Almacén: <strong>S3</strong> vía LocalStack <code className="support-panel__code">:4566</code>
        {" · "}
        vectores: <strong>pgvector</strong>
      </p>
      {!readOnly && (
        <div className="support-panel__toolbar">
          <button
            type="button"
            className="btn btn--small support-panel__upload"
            onClick={onPickFile}
            disabled={busy}
            aria-busy={busy}
          >
            {busy ? "Procesando…" : "Subir .md"}
          </button>
          <input
            ref={inputRef}
            type="file"
            className="support-panel__file-input"
            accept=".md,text/markdown,text/plain"
            aria-hidden
            tabIndex={-1}
            onChange={onFileChange}
            disabled={busy}
          />
        </div>
      )}
      {uploadUi.kind === "busy" && (
        <div className="support-panel__progress" role="status" aria-live="polite">
          <span className="support-panel__spinner" aria-hidden />
          <span className="support-panel__progress-text">{phaseLabel}</span>
        </div>
      )}
      {uploadUi.kind === "done" && (
        <div className="support-panel__result support-panel__result--ok small" role="status">
          <strong>S3</strong>: bucket <code className="support-panel__code">{uploadUi.bucket}</code>
          <br />
          Clave: <code className="support-panel__code">{shortKey(uploadUi.objectKey)}</code>
          <br />
          <strong>pgvector</strong>:{" "}
          {uploadUi.chunksIndexed === 1
            ? "1 fragmento indexado"
            : `${uploadUi.chunksIndexed} fragmentos indexados`}
          .
        </div>
      )}
      {uploadUi.kind === "local_only" && (
        <div className="support-panel__result support-panel__result--warn small" role="status">
          Solo en este navegador (no hubo respuesta del API de S3/pgvector). Comprueba que el backend tenga{" "}
          <code className="support-panel__code">DOCVIZ_SUPPORT_ENABLED=true</code>.
        </div>
      )}
      {uploadUi.kind === "error" && (
        <div className="support-panel__result support-panel__result--err small" role="alert">
          {uploadUi.message}
        </div>
      )}
      <ul className="support-panel__list" role="list">
        {documents.length === 0 ? (
          <li className="support-panel__empty muted small">
            {readOnly
              ? "No hay documentos de soporte indexados para este repositorio."
              : "No hay archivos de soporte. Sube un Markdown."}
          </li>
        ) : (
          documents.map((doc) => {
            const active = doc.id === selectedId;
            return (
              <li key={doc.id} className="support-panel__item">
                <button
                  type="button"
                  className={"support-panel__file" + (active ? " support-panel__file--active" : "")}
                  draggable
                  title={
                    (doc.name ? `${doc.name} · ` : "") +
                    "Clic para ver · arrastra a la pregunta para @[soporte:clave] (documento indexado en S3)"
                  }
                  onClick={() => onSelect(doc.id)}
                  onDragStart={(e) =>
                    setDocvizFileMentionOnDataTransfer(e.dataTransfer, "soporte", doc.objectKey ?? doc.name)
                  }
                >
                  <span className="support-panel__file-name">{doc.name}</span>
                </button>
                {!readOnly && (
                  <button
                    type="button"
                    className="support-panel__delete"
                    onClick={(ev) => {
                      ev.stopPropagation();
                      onDeleteClick(doc.id, doc.name);
                    }}
                    aria-label={`Eliminar ${doc.name}`}
                    title="Eliminar"
                  >
                    ×
                  </button>
                )}
              </li>
            );
          })
        )}
      </ul>
    </div>
  );
}
