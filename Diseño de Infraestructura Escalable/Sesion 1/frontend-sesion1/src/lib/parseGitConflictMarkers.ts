/**
 * Parser para archivos con marcadores estilo Git:
 * <<<<<<< … , ======= , >>>>>>> …
 */

export type NormalSegment = { type: "normal"; lines: string[] };

export type ConflictSegment = {
  type: "conflict";
  index: number;
  original: string[];
  suggested: string[];
};

export type DocumentSegment = NormalSegment | ConflictSegment;

export type ParsedConflictDoc =
  | { ok: true; segments: DocumentSegment[] }
  | { ok: false };

function isStartMarker(line: string): boolean {
  return line.startsWith("<<<<<<<");
}

function isMiddleMarker(line: string): boolean {
  return line === "=======";
}

function isEndMarker(line: string): boolean {
  return line.startsWith(">>>>>>>");
}

/**
 * Trocea el texto en segmentos normales y bloques de conflicto bien cerrados.
 * Si falta algún cierre, devuelve `ok: false` (el visor puede mostrar el texto crudo).
 */
export function parseGitConflictDocument(text: string): ParsedConflictDoc {
  const lines = text.split(/\r?\n/);
  const segments: DocumentSegment[] = [];
  let i = 0;
  let buf: string[] = [];
  let conflictIndex = 0;

  const flushNormal = () => {
    if (buf.length > 0) {
      segments.push({ type: "normal", lines: [...buf] });
      buf = [];
    }
  };

  while (i < lines.length) {
    const line = lines[i];
    if (isStartMarker(line)) {
      flushNormal();
      i++;
      const original: string[] = [];
      while (i < lines.length && !isMiddleMarker(lines[i])) {
        original.push(lines[i]);
        i++;
      }
      if (i >= lines.length || !isMiddleMarker(lines[i])) {
        return { ok: false };
      }
      i++;
      const suggested: string[] = [];
      while (i < lines.length && !isEndMarker(lines[i])) {
        suggested.push(lines[i]);
        i++;
      }
      if (i >= lines.length || !isEndMarker(lines[i])) {
        return { ok: false };
      }
      i++;
      segments.push({
        type: "conflict",
        index: conflictIndex,
        original,
        suggested,
      });
      conflictIndex++;
    } else {
      buf.push(line);
      i++;
    }
  }
  flushNormal();
  return { ok: true, segments };
}

/** Heurística rápida para decidir si vale la pena usar el visor de conflictos. */
export function hasGitConflictMarkers(text: string | null | undefined): boolean {
  if (text == null || text === "") return false;
  return (
    /(^|\r?\n)<<<<<<</.test(text) &&
    /(^|\r?\n)=======\s*(\r?\n|$)/.test(text) &&
    /(^|\r?\n)>>>>>>>/.test(text)
  );
}
