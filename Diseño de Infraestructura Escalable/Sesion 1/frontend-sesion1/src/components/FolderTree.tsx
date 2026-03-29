import type { FolderStructureDto } from "../types";

type Props = {
  root: FolderStructureDto;
  onSelectFile: (relativePath: string) => void;
  selectedPath: string | null;
};

export function FolderTree({ root, onSelectFile, selectedPath }: Props) {
  return (
    <div className="folder-tree">
      <div className="folder-tree__label">{root.folder || "raíz"}</div>
      <FolderRows
        node={root}
        pathPrefix=""
        onSelectFile={onSelectFile}
        selectedPath={selectedPath}
      />
    </div>
  );
}

function FolderRows({
  node,
  pathPrefix,
  onSelectFile,
  selectedPath,
}: {
  node: FolderStructureDto;
  pathPrefix: string;
  onSelectFile: (relativePath: string) => void;
  selectedPath: string | null;
}) {
  return (
    <ul className="folder-tree__list">
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
        return (
          <li key={sub.folder} className="folder-tree__folder">
            <div className="folder-tree__folder-name">{sub.folder}</div>
            <FolderRows
              node={sub}
              pathPrefix={nextPrefix}
              onSelectFile={onSelectFile}
              selectedPath={selectedPath}
            />
          </li>
        );
      })}
    </ul>
  );
}
