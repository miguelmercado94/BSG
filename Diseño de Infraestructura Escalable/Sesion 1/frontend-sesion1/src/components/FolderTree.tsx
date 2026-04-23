import { useCallback, useEffect, useState } from "react";
import { setDocvizFileMentionOnDataTransfer } from "../lib/docvizDrag";
import type { FolderStructureDto } from "../types";

/** Clave en el Set de expandidos para la carpeta raíz del repo (ej. "findu"). */
const ROOT_KEY = "";

type Props = {
  root: FolderStructureDto;
  onSelectFile: (relativePath: string) => void;
  selectedPath: string | null;
  /** Botón adicional por archivo (p. ej. visualizar en admin). */
  onViewFile?: (relativePath: string) => void;
};

function ChevronIcon({ open }: { open: boolean }) {
  return (
    <span className="folder-tree__chevron" aria-hidden>
      {open ? (
        <svg width="12" height="12" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
          <path d="M6 9l6 6 6-6" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />
        </svg>
      ) : (
        <svg width="12" height="12" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
          <path d="M9 6l6 6-6 6" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />
        </svg>
      )}
    </span>
  );
}

export function FolderTree({ root, onSelectFile, selectedPath, onViewFile }: Props) {
  /** Raíz expandida por defecto para ver archivos al instante (admin, workspace). */
  const [expanded, setExpanded] = useState<Set<string>>(() => new Set<string>([ROOT_KEY]));

  /** Abre la raíz y la cadena de carpetas que contiene el archivo seleccionado. */
  useEffect(() => {
    if (!selectedPath?.trim()) return;
    setExpanded((prev) => {
      const next = new Set(prev);
      next.add(ROOT_KEY);
      const parts = selectedPath.split("/").filter(Boolean);
      if (parts.length <= 1) {
        return next;
      }
      let acc = "";
      for (let i = 0; i < parts.length - 1; i++) {
        acc = i === 0 ? parts[0] : `${acc}/${parts[i]}`;
        next.add(acc);
      }
      return next;
    });
  }, [selectedPath]);

  const toggleFolder = useCallback((folderPath: string) => {
    setExpanded((prev) => {
      const next = new Set(prev);
      if (next.has(folderPath)) next.delete(folderPath);
      else next.add(folderPath);
      return next;
    });
  }, []);

  const rootLabel = root.folder || "raíz";
  const rootOpen = expanded.has(ROOT_KEY);

  return (
    <div className="folder-tree folder-tree--dark-panel">
      <button
        type="button"
        className="folder-tree__root-toggle"
        onClick={() => toggleFolder(ROOT_KEY)}
        aria-expanded={rootOpen}
        aria-label={rootOpen ? `Contraer repositorio ${rootLabel}` : `Expandir repositorio ${rootLabel}`}
      >
        <ChevronIcon open={rootOpen} />
        <span className="folder-tree__root-name">{rootLabel}</span>
      </button>
      {rootOpen && (
        <ul className="folder-tree__list folder-tree__list--root">
          <FolderRows
            node={root}
            pathPrefix=""
            expanded={expanded}
            toggleFolder={toggleFolder}
            onSelectFile={onSelectFile}
            onViewFile={onViewFile}
            selectedPath={selectedPath}
          />
        </ul>
      )}
    </div>
  );
}

function FolderRows({
  node,
  pathPrefix,
  expanded,
  toggleFolder,
  onSelectFile,
  onViewFile,
  selectedPath,
}: {
  node: FolderStructureDto;
  pathPrefix: string;
  expanded: Set<string>;
  toggleFolder: (folderPath: string) => void;
  onSelectFile: (relativePath: string) => void;
  onViewFile?: (relativePath: string) => void;
  selectedPath: string | null;
}) {
  const files = node.archivos ?? [];
  const subfolders = node.folders ?? [];

  return (
    <>
      {files.map((f) => {
        const rel = pathPrefix ? `${pathPrefix}/${f}` : f;
        const active = selectedPath === rel;
        return (
          <li key={rel}>
            <div className="folder-tree__file-row">
              <button
                type="button"
                className={`folder-tree__file${active ? " is-active" : ""}`}
                draggable
                title="Clic para abrir · arrastra a la pregunta para insertar @[repo:ruta/completa] (mejor recuperación RAG)"
                onClick={() => onSelectFile(rel)}
                onDragStart={(e) => setDocvizFileMentionOnDataTransfer(e.dataTransfer, "repo", rel)}
              >
                {f}
              </button>
              {onViewFile != null && (
                <button
                  type="button"
                  className="folder-tree__file-view"
                  aria-label={`Visualizar ${f}`}
                  title="Visualizar"
                  onClick={() => onViewFile(rel)}
                >
                  <svg width="14" height="14" viewBox="0 0 24 24" aria-hidden>
                    <path
                      fill="currentColor"
                      d="M12 4.5C7 4.5 2.73 7.61 1 12c1.73 4.39 6 7.5 11 7.5s9.27-3.11 11-7.5c-1.73-4.39-6-7.5-11-7.5zM12 17c-2.76 0-5-2.24-5-5s2.24-5 5-5 5 2.24 5 5-2.24 5-5 5zm0-8c-1.66 0-3 1.34-3 3s1.34 3 3 3 3-1.34 3-3-1.34-3-3-3z"
                    />
                  </svg>
                </button>
              )}
            </div>
          </li>
        );
      })}
      {subfolders.map((sub) => {
        const nextPrefix = pathPrefix ? `${pathPrefix}/${sub.folder}` : sub.folder;
        const isOpen = expanded.has(nextPrefix);
        return (
          <li key={nextPrefix} className="folder-tree__folder">
            <button
              type="button"
              className="folder-tree__folder-toggle"
              onClick={() => toggleFolder(nextPrefix)}
              aria-expanded={isOpen}
              aria-label={isOpen ? `Contraer carpeta ${sub.folder}` : `Expandir carpeta ${sub.folder}`}
            >
              <ChevronIcon open={isOpen} />
              <span className="folder-tree__folder-name">{sub.folder}</span>
            </button>
            {isOpen && (
              <ul className="folder-tree__list folder-tree__list--nested">
                <FolderRows
                  node={sub}
                  pathPrefix={nextPrefix}
                  expanded={expanded}
                  toggleFolder={toggleFolder}
                  onSelectFile={onSelectFile}
                  onViewFile={onViewFile}
                  selectedPath={selectedPath}
                />
              </ul>
            )}
          </li>
        );
      })}
    </>
  );
}
