import { useCallback, useEffect, useMemo, useRef, useState } from "react";

import {
  buildResolvedDocvizMerge,
  hasDocvizMergeMarkers,
  MARKER_DIV,
  MARKER_OURS,
  MARKER_THEIRS,
  parseDocvizMerge,
} from "../lib/docvizConflictMarkers";

type Choice = "ours" | "theirs" | "both";

type Props = {
  text: string;
  /** Contenido del archivo listo para escribir en el clon (sin marcadores). */
  onResolvedChange: (resolvedFileText: string) => void;
};

/**
 * Vista estilo editor (similar a VS Code): bloques coloreados para repositorio vs propuesto y acciones por conflicto.
 */
export function WorkAreaConflictViewer({ text, onResolvedChange }: Props) {
  const parsed = useMemo(() => parseDocvizMerge(text), [text]);
  const [choice, setChoice] = useState<Choice>("theirs");
  /** Evita resetear la elección del usuario en cada re-render si el contenido es el mismo valor. */
  const prevMarkersBlobRef = useRef<string | null>(null);

  const resolvedPreview = useMemo(() => buildResolvedDocvizMerge(text, choice), [text, choice]);

  const applyChoice = useCallback(
    (c: Choice) => {
      setChoice(c);
      onResolvedChange(buildResolvedDocvizMerge(text, c));
    },
    [text, onResolvedChange],
  );

  useEffect(() => {
    if (!hasDocvizMergeMarkers(text)) {
      prevMarkersBlobRef.current = null;
      onResolvedChange(text);
      return;
    }
    if (prevMarkersBlobRef.current === text) {
      return;
    }
    prevMarkersBlobRef.current = text;
    setChoice("theirs");
    onResolvedChange(buildResolvedDocvizMerge(text, "theirs"));
  }, [text, onResolvedChange]);

  if (!parsed) {
    return (
      <pre className="file-preview" spellCheck={false}>
        {text}
      </pre>
    );
  }

  return (
    <div className="work-area-conflict" role="region" aria-label="Conflicto de merge DocViz">
      <div className="work-area-conflict__toolbar">
        <button
          type="button"
          className={`work-area-conflict__toolbar-btn${choice === "ours" ? " work-area-conflict__toolbar-btn--active" : ""}`}
          onClick={() => applyChoice("ours")}
        >
          Aceptar del repositorio
        </button>
        <span className="work-area-conflict__toolbar-sep" aria-hidden>
          |
        </span>
        <button
          type="button"
          className={`work-area-conflict__toolbar-btn${choice === "theirs" ? " work-area-conflict__toolbar-btn--active" : ""}`}
          onClick={() => applyChoice("theirs")}
        >
          Aceptar propuesto
        </button>
        <span className="work-area-conflict__toolbar-sep" aria-hidden>
          |
        </span>
        <button
          type="button"
          className={`work-area-conflict__toolbar-btn${choice === "both" ? " work-area-conflict__toolbar-btn--active" : ""}`}
          onClick={() => applyChoice("both")}
        >
          Aceptar ambos
        </button>
      </div>

      <div className="work-area-conflict__preview-hint muted small" role="status">
        Texto que se usará al guardar o descargar (cambia al pulsar arriba). Luego usa «Editar» en la barra para afinar y
        guardar.
      </div>
      <pre className="work-area-conflict__preview-body" spellCheck={false}>
        {resolvedPreview}
      </pre>

      <div className="work-area-conflict__marker work-area-conflict__marker--start">{MARKER_OURS}</div>
      <pre className="work-area-conflict__block work-area-conflict__block--ours" spellCheck={false}>
        {parsed.original}
      </pre>

      <div className="work-area-conflict__marker work-area-conflict__marker--mid">{MARKER_DIV}</div>

      <pre className="work-area-conflict__block work-area-conflict__block--theirs" spellCheck={false}>
        {parsed.revised}
      </pre>

      <div className="work-area-conflict__marker work-area-conflict__marker--end">{MARKER_THEIRS}</div>
    </div>
  );
}
