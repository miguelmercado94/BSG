import { useCallback, useEffect, useState } from "react";
import type { FolderStructureDto } from "../types";

/** Clave en el Set de expandidos para la carpeta raíz del repo (ej. "findu"). */
const ROOT_KEY = "";

type Props = {
  root: FolderStructureDto;
  onSelectFile: (relativePath: string) => void;
  selectedPath: string | null;
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

export function FolderTree({ root, onSelectFile, selectedPath }: Props) {
  const [expanded, setExpanded] = useState<Set<string>>(() => new Set());

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
  selectedPath,
}: {
  node: FolderStructureDto;
  pathPrefix: string;
  expanded: Set<string>;
  toggleFolder: (folderPath: string) => void;
  onSelectFile: (relativePath: string) => void;
  selectedPath: string | null;
}) {
  return (
    <>
      {node.archivos.map((f) => {
        const rel = pathPrefix ? `${pathPrefix}/${f}` : f;
        const active = selectedPath === rel;
        return (
          <li key={rel}>
            <button
              type="button"
              className={`folder-tree__file${active ? " is-active" : ""}`}
              onClick={() => onSelectFile(rel)}
            >
              {f}
            </button>
          </li>
        );
      })}
      {node.folders.map((sub) => {
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
