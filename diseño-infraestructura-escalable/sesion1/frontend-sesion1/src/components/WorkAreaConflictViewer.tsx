import { useCallback, useEffect, useMemo, useRef, useState } from "react";

import {
  buildResolvedDocvizMerge,
  hasDocvizMergeMarkers,
  parseDocvizMerge,
} from "../lib/docvizConflictMarkers";

type Choice = "ours" | "theirs";

type Props = {
  text: string;
  /** Texto resuelto para guardar (buffer por defecto «propuesto»). */
  onResolvedChange: (resolvedFileText: string) => void;
  /** Solo al pulsar «Aceptar del repositorio» o «Aceptar propuesto»: sustituye el borrador en el padre y quita marcadores. */
  onCommitResolution?: (resolvedFileText: string) => void;
};

/**
 * Solo dos paneles antes de elegir: propuesta (azul, arriba) y repositorio (verde, abajo).
 * Tras elegir, el padre sustituye `content` sin marcadores → vista única plana y edición habilitada allí.
 */
export function WorkAreaConflictViewer({ text, onResolvedChange, onCommitResolution }: Props) {
  const parsed = useMemo(() => parseDocvizMerge(text), [text]);
  const [choice, setChoice] = useState<Choice>("theirs");
  const prevMarkersBlobRef = useRef<string | null>(null);

  const applyChoice = useCallback(
    (c: Choice) => {
      setChoice(c);
      const resolved = buildResolvedDocvizMerge(text, c);
      onResolvedChange(resolved);
      onCommitResolution?.(resolved);
    },
    [text, onResolvedChange, onCommitResolution],
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
    <div className="work-area-conflict" role="region" aria-label="Comparar propuesta y repositorio">
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
      </div>

      <div className="work-area-conflict__hint muted small" role="status">
        Arriba la propuesta del modelo; abajo el texto del repositorio. Al elegir una opción verás solo el resultado y
        podrás editar o guardar desde la barra.
      </div>

      <div className="work-area-conflict__caption work-area-conflict__caption--theirs">Propuesta</div>
      <pre className="work-area-conflict__block work-area-conflict__block--theirs" spellCheck={false}>
        {parsed.revised}
      </pre>

      <div className="work-area-conflict__caption work-area-conflict__caption--ours">Repositorio (original)</div>
      <pre className="work-area-conflict__block work-area-conflict__block--ours" spellCheck={false}>
        {parsed.original}
      </pre>
    </div>
  );
}
