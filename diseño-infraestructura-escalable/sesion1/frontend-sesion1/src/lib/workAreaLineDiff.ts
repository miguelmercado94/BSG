import { diffLines } from "diff";

import type { WorkAreaDiffLine } from "../types";

/**
 * Diff por líneas (Myers, vía `diff`), alineado con {@code WorkAreaFullFileDiffBuilder} en el backend.
 */
export function buildWorkAreaDiffLines(original: string, revised: string): WorkAreaDiffLine[] {
  const changes = diffLines(original ?? "", revised ?? "");
  const out: WorkAreaDiffLine[] = [];
  for (const ch of changes) {
    const value = ch.value;
    if (value.length === 0 && !ch.added && !ch.removed) {
      continue;
    }
    const lines = value.split(/\r?\n/);
    const lastEmpty = lines.length > 0 && lines[lines.length - 1] === "";
    const trimmed = lastEmpty ? lines.slice(0, -1) : lines;
    for (const text of trimmed) {
      if (ch.added) {
        out.push({ kind: "added", text });
      } else if (ch.removed) {
        out.push({ kind: "removed", text });
      } else {
        out.push({ kind: "context", text });
      }
    }
  }
  return out;
}
