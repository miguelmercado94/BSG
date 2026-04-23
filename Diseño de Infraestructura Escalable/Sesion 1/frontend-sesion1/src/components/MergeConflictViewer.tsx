import {
  hasDocvizMergeMarkers,
  parseDocvizMerge,
} from "../lib/docvizConflictMarkers";

export const MARK_PAST = ">>> past >>>";
export const MARK_CURRENT = ">>> current >>>";

/** Extrae el texto «propuesto» del bloque DocViz (para POST /apply-final). Incluye formato merge y `>>> past/current >>>`. */
export function extractRevisedFromDisplayMarkers(text: string): string | null {
  const m = parseDocvizMerge(text);
  if (m) return m.revised;
  return extractRevisedFromPastCurrent(text);
}

/** @deprecated Usar {@link extractRevisedFromDisplayMarkers}; se mantiene por compatibilidad. */
export function extractRevisedFromMergeMarkers(text: string): string | null {
  return extractRevisedFromDisplayMarkers(text);
}

function extractRevisedFromPastCurrent(text: string): string | null {
  if (!text.includes(MARK_PAST) || !text.includes(MARK_CURRENT)) {
    return null;
  }
  const lines = text.split(/\r?\n/);
  const out: string[] = [];
  let i = 0;
  while (i < lines.length) {
    const line = lines[i];
    if (line.trim() === MARK_PAST) {
      i++;
      while (i < lines.length && lines[i].trim() !== MARK_CURRENT) i++;
      if (i >= lines.length) return null;
      i++;
      while (i < lines.length && lines[i].trim() !== MARK_PAST) {
        out.push(lines[i]);
        i++;
      }
      continue;
    }
    out.push(line);
    i++;
  }
  return out.join("\n");
}

export function isMergeConflictText(text: string | undefined | null): boolean {
  return hasDocvizMergeMarkers(text ?? "");
}

export function isPastCurrentMarkerText(text: string | undefined | null): boolean {
  if (text == null || text === "") return false;
  return text.includes(MARK_PAST) && text.includes(MARK_CURRENT);
}

export function isWorkAreaMarkedPreview(text: string | undefined | null): boolean {
  return isMergeConflictText(text) || isPastCurrentMarkerText(text);
}
