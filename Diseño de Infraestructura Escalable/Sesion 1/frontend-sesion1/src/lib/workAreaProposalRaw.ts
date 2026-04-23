import type { WorkAreaFileProposal } from "../types";

/**
 * Si el backend no envía `content`, muestra el payload relevante como texto (depuración).
 * No sustituye a `content`: solo último recurso para ver qué llegó del servidor.
 */
export function workAreaProposalFallbackPayloadText(p: WorkAreaFileProposal): string {
  if (
    p.artifactViewOnly &&
    (p.s3PresignedUrl?.trim() || (Boolean(p.s3Bucket?.trim()) && Boolean(p.s3ObjectKey?.trim())))
  ) {
    return [
      "Vista previa: el contenido aún no se cargó desde S3 (o la URL firmada expiró / falló la red).",
      "Prueba a recargar la lista del área de trabajo o vuelve a abrir la tarea.",
      "",
      `Bucket: ${p.s3Bucket ?? "—"}`,
      `Clave: ${p.s3ObjectKey ?? p.fileName}`,
    ].join("\n");
  }
  return JSON.stringify(
    {
      id: p.id,
      fileName: p.fileName,
      extension: p.extension,
      sourcePath: p.sourcePath,
      draftVersion: p.draftVersion,
      draftRelativePath: p.draftRelativePath,
      content: p.content ?? null,
      changeBlocks: p.changeBlocks ?? null,
      lineEdits: p.lineEdits ?? null,
      diffLinesSample: p.diffLines?.slice(0, 80) ?? null,
      diffLinesTotal: p.diffLines?.length ?? 0,
    },
    null,
    2,
  );
}
