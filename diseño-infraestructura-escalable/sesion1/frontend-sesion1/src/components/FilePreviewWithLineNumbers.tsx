type Props = {
  text: string;
  className?: string;
};

/**
 * Vista de archivo monospace con margen de números de línea (scroll unificado).
 */
export function FilePreviewWithLineNumbers({ text, className }: Props) {
  const lines = text.split(/\r?\n/);
  return (
    <div
      className={`file-preview file-preview--numbered ${className ?? ""}`.trim()}
      role="region"
      aria-label="Vista previa con números de línea"
    >
      <div className="file-preview__numbered-inner">
        {lines.map((line, i) => (
          <div key={i} className="file-preview__row">
            <span className="file-preview__ln" aria-hidden>
              {i + 1}
            </span>
            <span className="file-preview__line">{line.length === 0 ? "\u00a0" : line}</span>
          </div>
        ))}
      </div>
    </div>
  );
}
