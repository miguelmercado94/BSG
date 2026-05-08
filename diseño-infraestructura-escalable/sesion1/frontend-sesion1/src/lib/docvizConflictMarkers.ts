/** Alineado con {@link com.bsg.docviz.util.WorkAreaMergeConflictFormatter} (ORIGINAL / SUGGESTION + cierre =======). */
export const MARKER_OURS = "<<<<<<< ORIGINAL";
export const MARKER_DIV = "=======";
export const MARKER_THEIRS = ">>>>>>> SUGGESTION";

const LEGACY_OURS = "<<<<<<< DocViz (original)";
const LEGACY_THEIRS = ">>>>>>> DocViz (propuesto)";

function pickOurs(text: string): string | null {
  if (text.includes(MARKER_OURS)) return MARKER_OURS;
  if (text.includes(LEGACY_OURS)) return LEGACY_OURS;
  return null;
}

function indexOfTheirs(text: string, from: number): number {
  const a = text.indexOf(MARKER_THEIRS, from);
  const b = text.indexOf(LEGACY_THEIRS, from);
  if (a < 0) return b;
  if (b < 0) return a;
  return Math.min(a, b);
}

function skipWsLines(s: string, from: number): number {
  let i = from;
  const n = s.length;
  while (i < n) {
    const c = s.charCodeAt(i);
    if (c === 10 || c === 13 || c === 32 || c === 9) i++;
    else break;
  }
  return i;
}

function indexOfLineExactly(s: string, marker: string, from: number): number {
  let i = from;
  const n = s.length;
  while (i < n) {
    const lineEnd = s.indexOf("\n", i);
    const end = lineEnd < 0 ? n : lineEnd;
    const line = s.slice(i, end).trim();
    if (line === marker) return i;
    if (lineEnd < 0) break;
    i = lineEnd + 1;
  }
  return -1;
}

function trimTrailNl(chunk: string): string {
  if (chunk.endsWith("\r\n")) return chunk.slice(0, -2);
  if (chunk.endsWith("\n") || chunk.endsWith("\r")) return chunk.slice(0, -1);
  return chunk;
}

export function hasDocvizMergeMarkers(text: string | null | undefined): boolean {
  if (text == null || text === "") return false;
  const hasOurs = text.includes(MARKER_OURS) || text.includes(LEGACY_OURS);
  const hasTheirs = text.includes(MARKER_THEIRS) || text.includes(LEGACY_THEIRS);
  return hasOurs && text.includes(MARKER_DIV) && hasTheirs;
}

/** Parsea un bloque DocViz (orden nuevo con cierre ======= u orden legado). */
export function parseDocvizMerge(text: string): { original: string; revised: string } | null {
  const ours = pickOurs(text);
  if (ours == null || !text.includes(MARKER_DIV)) return null;

  const start = text.indexOf(ours);
  const afterOurs = text.indexOf("\n", start);
  if (afterOurs < 0) return null;

  const firstDiv = text.indexOf(MARKER_DIV, afterOurs + 1);
  if (firstDiv < 0) return null;
  const afterFirstDiv = text.indexOf("\n", firstDiv);
  if (afterFirstDiv < 0) return null;

  let original = text.slice(afterOurs + 1, firstDiv);
  original = trimTrailNl(original);

  const bodyStart = afterFirstDiv + 1;
  const pos = skipWsLines(text, bodyStart);

  let revised: string;
  if (pos < text.length && text.startsWith(">>>>>>>", pos)) {
    const theirsLineEnd = text.indexOf("\n", pos);
    if (theirsLineEnd < 0) return null;
    const revStart = theirsLineEnd + 1;
    const closeDiv = indexOfLineExactly(text, MARKER_DIV, revStart);
    if (closeDiv < 0) revised = trimTrailNl(text.slice(revStart));
    else revised = trimTrailNl(text.slice(revStart, closeDiv));
  } else {
    const theirsIdx = indexOfTheirs(text, bodyStart);
    if (theirsIdx < 0) return null;
    revised = trimTrailNl(text.slice(bodyStart, theirsIdx));
  }

  const hasTheirsMarker = text.includes(MARKER_THEIRS) || text.includes(LEGACY_THEIRS);
  if (!hasTheirsMarker) return null;
  return { original, revised };
}

/** Sustituye el primer bloque DocViz por el contenido elegido; conserva prefijo/sufijo fuera del bloque. */
export function buildResolvedDocvizMerge(text: string, choice: "ours" | "theirs" | "both"): string {
  const parsed = parseDocvizMerge(text);
  if (!parsed) return text;
  const ours = pickOurs(text);
  if (ours == null) return text;
  const blockStart = text.indexOf(ours);
  const afterOurs = text.indexOf("\n", blockStart);
  if (afterOurs < 0) return text;
  const firstDiv = text.indexOf(MARKER_DIV, afterOurs + 1);
  if (firstDiv < 0) return text;
  const afterFirstDiv = text.indexOf("\n", firstDiv);
  if (afterFirstDiv < 0) return text;
  const bodyStart = afterFirstDiv + 1;
  const pos = skipWsLines(text, bodyStart);

  let blockEndExclusive: number;
  if (pos < text.length && text.startsWith(">>>>>>>", pos)) {
    const theirsLineEnd = text.indexOf("\n", pos);
    if (theirsLineEnd < 0) return text;
    const revStart = theirsLineEnd + 1;
    const closeDiv = indexOfLineExactly(text, MARKER_DIV, revStart);
    if (closeDiv < 0) {
      blockEndExclusive = text.length;
    } else {
      const afterClose = text.indexOf("\n", closeDiv);
      blockEndExclusive = afterClose < 0 ? text.length : afterClose + 1;
    }
  } else {
    const theirsIdx = indexOfTheirs(text, bodyStart);
    if (theirsIdx < 0) return text;
    const markerLen =
      text.startsWith(MARKER_THEIRS, theirsIdx) ? MARKER_THEIRS.length : LEGACY_THEIRS.length;
    const afterTheirs = text.indexOf("\n", theirsIdx + markerLen);
    blockEndExclusive = afterTheirs < 0 ? text.length : afterTheirs + 1;
  }

  const prefix = blockStart > 0 ? text.slice(0, blockStart) : "";
  const suffix = text.slice(blockEndExclusive);
  let inner: string;
  if (choice === "ours") inner = parsed.original;
  else if (choice === "theirs") inner = parsed.revised;
  else inner = parsed.original + "\n" + parsed.revised;
  return prefix + inner + suffix;
}
