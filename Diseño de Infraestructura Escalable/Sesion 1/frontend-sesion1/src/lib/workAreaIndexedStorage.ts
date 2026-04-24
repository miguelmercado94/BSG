/**
 * Persiste en localStorage qué archivos ya se indexaron en RAG (chip azul tras F5 o nuevo login).
 * Clave: usuario + código HU + ruta aceptada en el repo.
 */
const PREFIX = "docviz:workAreaIndexed:v1:";

function normPath(rel: string): string {
  return rel.trim().replace(/\\/g, "/");
}

function key(userId: string, huCode: string, acceptedRelativePath: string): string {
  return `${PREFIX}${userId}:${huCode}:${normPath(acceptedRelativePath)}`;
}

export function saveWorkAreaIndexed(
  userId: string,
  huCode: string,
  acceptedRelativePath: string,
  chunksIndexed: number,
): void {
  const uid = userId?.trim();
  const hu = huCode?.trim();
  if (!uid || !hu || !acceptedRelativePath?.trim()) return;
  try {
    localStorage.setItem(
      key(uid, hu, acceptedRelativePath),
      JSON.stringify({ chunksIndexed, savedAt: Date.now() }),
    );
  } catch {
    /* private mode */
  }
}

export function loadWorkAreaIndexed(
  userId: string | undefined,
  huCode: string | undefined,
  acceptedRelativePath: string | undefined,
): { chunksIndexed: number } | null {
  const uid = userId?.trim();
  const hu = huCode?.trim();
  const rel = acceptedRelativePath?.trim();
  if (!uid || !hu || !rel) return null;
  try {
    const raw = localStorage.getItem(key(uid, hu, rel));
    if (!raw) return null;
    const j = JSON.parse(raw) as { chunksIndexed?: number };
    if (typeof j.chunksIndexed !== "number") return null;
    return { chunksIndexed: j.chunksIndexed };
  } catch {
    return null;
  }
}
