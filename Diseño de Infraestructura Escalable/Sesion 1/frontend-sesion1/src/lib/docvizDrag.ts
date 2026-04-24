/**
 * Arrastrar archivo → soltar en la pregunta RAG.
 * - Repo: `@[repo:ruta/relativa/al/archivo.java]` (el backend carga el archivo completo desde Git).
 * - Soporte (S3): `@[soporte:clave/objectKey]` (coincide con la fuente vectorial `soporte:…`).
 */
export const DOCVIZ_FILE_MENTION_MIME = "application/x-docviz-file-mention";

export function fileMentionFromRepoPath(relativePath: string): string {
  const p = relativePath.replace(/\\/g, "/").trim().replace(/^\/+/, "");
  return `@[repo:${p}]`;
}

/** objectKey tal como en el índice / S3 (sin prefijo soporte:) */
export function fileMentionFromSupportObjectKey(objectKey: string): string {
  return `@[soporte:${objectKey.trim()}]`;
}

/** Solo nombre de archivo (el backend intenta resolver la ruta en el árbol). */
export function fileMentionFromFileName(fileName: string): string {
  return `@[${fileName.trim()}]`;
}

export function setDocvizFileMentionOnDataTransfer(
  dt: DataTransfer,
  kind: "repo" | "soporte",
  pathOrObjectKey: string,
): void {
  const token =
    kind === "repo" ? fileMentionFromRepoPath(pathOrObjectKey) : fileMentionFromSupportObjectKey(pathOrObjectKey);
  dt.setData("text/plain", token);
  try {
    dt.setData(DOCVIZ_FILE_MENTION_MIME, token);
  } catch {
    /* algunos entornos limitan tipos personalizados */
  }
  dt.effectAllowed = "copy";
}

export function getDocvizFileMentionFromDataTransfer(dt: DataTransfer): string | null {
  try {
    const v = dt.getData(DOCVIZ_FILE_MENTION_MIME).trim();
    if (v) return v;
  } catch {
    /* ignore */
  }
  const plain = dt.getData("text/plain").trim();
  if (/^@\[[^\]]+\]$/.test(plain)) return plain;
  return null;
}
