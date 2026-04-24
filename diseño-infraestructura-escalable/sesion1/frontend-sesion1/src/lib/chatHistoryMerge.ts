import type { ChatHistoryEntry } from "../types";

/**
 * Tras el stream, Firestore puede aún no incluir el último turno (persistencia asíncrona).
 * Si hacemos `setChatTurns(rows)` a ciegas, se pierde el mensaje local con el JSON de propuestas.
 */
export function mergeFirestoreHistoryWithLocalStream(
  rows: ChatHistoryEntry[],
  local: ChatHistoryEntry | undefined,
  question: string,
): ChatHistoryEntry[] {
  if (!local?.answer?.trim()) {
    return rows;
  }
  const last = rows.length > 0 ? rows[rows.length - 1] : undefined;
  if (!last || last.question !== question) {
    return [...rows, local];
  }
  const useAnswer =
    local.answer.length > (last.answer?.length ?? 0) ? local.answer : last.answer;
  const useSources = local.sources.length > 0 ? local.sources : last.sources;
  return [...rows.slice(0, -1), { ...last, answer: useAnswer, sources: useSources }];
}
