type Props = {
  availableTags: string[];
  selectedTags: string[];
  onToggle: (tag: string) => void;
};

export function TagDiamondPicker({ availableTags, selectedTags, onToggle }: Props) {
  if (availableTags.length === 0) {
    return <p className="muted small">No hay etiquetas disponibles desde el servidor.</p>;
  }

  return (
    <div className="tag-diamond-picker" role="group" aria-label="Etiquetas de contexto">
      {availableTags.map((tag) => {
        const on = selectedTags.includes(tag);
        return (
          <button
            key={tag}
            type="button"
            className={`tag-diamond ${on ? "tag-diamond--selected" : ""}`}
            onClick={() => onToggle(tag)}
            title={on ? "Quitar etiqueta" : "Añadir etiqueta"}
          >
            <span className="tag-diamond__label">{tag}</span>
          </button>
        );
      })}
    </div>
  );
}
