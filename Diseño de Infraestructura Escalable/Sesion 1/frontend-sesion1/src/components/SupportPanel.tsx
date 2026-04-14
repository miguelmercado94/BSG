import { useCallback, useRef, type ChangeEvent } from "react";

import type { SupportDocument } from "../types";

import { normalizeMdFilename } from "../hooks/useSupportDocuments";

type Props = {
  documents: SupportDocument[];
  selectedId: string | null;
  onSelect: (id: string) => void;
  onUpload: (fileName: string, content: string) => void;
  onDelete: (id: string) => void;
};

export function SupportPanel({ documents, selectedId, onSelect, onUpload, onDelete }: Props) {
  const inputRef = useRef<HTMLInputElement>(null);

  const onPickFile = useCallback(() => {
    inputRef.current?.click();
  }, []);

  const onFileChange = useCallback(
    (e: ChangeEvent<HTMLInputElement>) => {
      const file = e.target.files?.[0];
      e.target.value = "";
      if (!file) return;
      const name = normalizeMdFilename(file.name);
      const reader = new FileReader();
      reader.onload = () => {
        const text = typeof reader.result === "string" ? reader.result : "";
        onUpload(name, text);
      };
      reader.onerror = () => {
        /* ignore */
      };
      reader.readAsText(file, "UTF-8");
    },
    [onUpload],
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

  return (
    <div className="support-panel">
      <div className="support-panel__toolbar">
        <button type="button" className="btn btn--small support-panel__upload" onClick={onPickFile}>
          Subir .md
        </button>
        <input
          ref={inputRef}
          type="file"
          className="support-panel__file-input"
          accept=".md,text/markdown,text/plain"
          aria-hidden
          tabIndex={-1}
          onChange={onFileChange}
        />
      </div>
      <ul className="support-panel__list" role="list">
        {documents.length === 0 ? (
          <li className="support-panel__empty muted small">No hay archivos de soporte. Sube un Markdown.</li>
        ) : (
          documents.map((doc) => {
            const active = doc.id === selectedId;
            return (
              <li key={doc.id} className="support-panel__item">
                <button
                  type="button"
                  className={"support-panel__file" + (active ? " support-panel__file--active" : "")}
                  onClick={() => onSelect(doc.id)}
                  title={doc.name}
                >
                  <span className="support-panel__file-name">{doc.name}</span>
                </button>
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
              </li>
            );
          })
        )}
      </ul>
    </div>
  );
}
