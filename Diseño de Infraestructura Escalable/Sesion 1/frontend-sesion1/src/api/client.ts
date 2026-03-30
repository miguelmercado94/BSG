import type {
  ConnectResponse,
  FileContentResponse,
  GitConnectRequest,
  IngestProgressEvent,
  TagsResponse,
  VectorChatResponse,
  VectorIngestResponse,
} from "../types";

export const USER_HEADER = "X-DocViz-User";

const storedKey = "docviz_user";

export function getUserId(): string {
  return localStorage.getItem(storedKey) ?? "";
}

export function setUserId(id: string): void {
  localStorage.setItem(storedKey, id.trim());
}

function apiBase(): string {
  const v = import.meta.env.VITE_API_URL;
  if (v === undefined || v === "") {
    throw new Error(
      "Falta VITE_API_URL: define en .env la URL base del API (p. ej. /api con el proxy de Vite en local)."
    );
  }
  return v.replace(/\/$/, "");
}

async function parseJson<T>(res: Response): Promise<T> {
  const text = await res.text();
  if (!res.ok) {
    let msg = text || res.statusText;
    try {
      const j = JSON.parse(text) as { error?: string; message?: string };
      msg = j.error ?? j.message ?? msg;
    } catch {
      /* ignore */
    }
    throw new Error(msg);
  }
  if (!text) return {} as T;
  return JSON.parse(text) as T;
}

function headers(extra?: HeadersInit): HeadersInit {
  const uid = getUserId();
  if (!uid) {
    throw new Error("Falta el identificador de usuario (DocViz).");
  }
  return {
    "Content-Type": "application/json",
    [USER_HEADER]: uid,
    ...extra,
  };
}

export async function connectGit(body: GitConnectRequest): Promise<ConnectResponse> {
  const res = await fetch(`${apiBase()}/connect/git`, {
    method: "POST",
    headers: headers(),
    body: JSON.stringify(body),
  });
  return parseJson<ConnectResponse>(res);
}

export async function fetchTags(): Promise<TagsResponse> {
  const res = await fetch(`${apiBase()}/tags`, { headers: headers() });
  return parseJson<TagsResponse>(res);
}

export async function fetchFileContent(queryPath: string): Promise<FileContentResponse> {
  const q = encodeURIComponent(queryPath);
  const res = await fetch(`${apiBase()}/files/content?query=${q}`, { headers: headers() });
  return parseJson<FileContentResponse>(res);
}

export async function vectorIngest(): Promise<VectorIngestResponse> {
  const res = await fetch(`${apiBase()}/vector/ingest`, {
    method: "POST",
    headers: headers(),
  });
  return parseJson<VectorIngestResponse>(res);
}

/**
 * Ingesta con streaming NDJSON: emite START, FILE, PROGRESS por archivo y DONE (o ERROR).
 */
export async function vectorIngestStream(
  onProgress: (ev: IngestProgressEvent) => void,
): Promise<VectorIngestResponse> {
  const res = await fetch(`${apiBase()}/vector/ingest/stream`, {
    method: "POST",
    headers: {
      ...headers(),
      Accept: "application/x-ndjson, application/json;q=0.9, */*;q=0.1",
    },
  });
  // Backend antiguo o preview sin proxy: no existe la ruta de streaming; usar ingesta clásica.
  if (res.status === 404) {
    return vectorIngestFallbackProgress(onProgress);
  }
  if (!res.ok) {
    const text = await res.text();
    let msg = text || res.statusText;
    try {
      const j = JSON.parse(text) as { error?: string; message?: string };
      msg = j.error ?? j.message ?? msg;
    } catch {
      /* ignore */
    }
    throw new Error(msg);
  }
  const reader = res.body?.getReader();
  if (!reader) {
    throw new Error("Respuesta de ingesta sin cuerpo legible");
  }
  const decoder = new TextDecoder();
  let buffer = "";
  let lastDone: VectorIngestResponse | null = null;

  function consumeNdjsonLine(trimmed: string): void {
    if (!trimmed) return;
    const ev = JSON.parse(trimmed) as IngestProgressEvent;
    onProgress(ev);
    if (ev.phase === "DONE") {
      lastDone = {
        filesProcessed: ev.filesProcessed ?? 0,
        chunksIndexed: ev.chunksIndexed ?? 0,
        skipped: ev.skipped ?? [],
        namespace: ev.namespace ?? "",
      };
    }
    if (ev.phase === "ERROR") {
      throw new Error(ev.error ?? "Error de ingesta");
    }
  }

  while (true) {
    const { done, value } = await reader.read();
    if (done) {
      // Últimos bytes del decoder (caracteres UTF-8 partidos entre chunks)
      buffer += decoder.decode();
      break;
    }
    buffer += decoder.decode(value, { stream: true });
    const lines = buffer.split("\n");
    buffer = lines.pop() ?? "";
    for (const line of lines) {
      consumeNdjsonLine(line.trim());
    }
  }
  // La última línea suele ir sin \n al cerrar el stream; antes se quedaba sin parsear (faltaba DONE).
  const tail = buffer.trim();
  if (tail) {
    consumeNdjsonLine(tail);
  }
  if (!lastDone) {
    throw new Error("La ingesta terminó sin confirmación del servidor");
  }
  return lastDone;
}

/** Ingesta sin NDJSON (sin barra de progreso por archivo); emite START + DONE al terminar. */
async function vectorIngestFallbackProgress(
  onProgress: (ev: IngestProgressEvent) => void,
): Promise<VectorIngestResponse> {
  onProgress({ phase: "START", totalFiles: 0 });
  const r = await vectorIngest();
  onProgress({
    phase: "DONE",
    filesProcessed: r.filesProcessed,
    chunksIndexed: r.chunksIndexed,
    namespace: r.namespace,
    skipped: r.skipped,
  });
  return r;
}

export async function vectorChat(question: string): Promise<VectorChatResponse> {
  const res = await fetch(`${apiBase()}/vector/chat`, {
    method: "POST",
    headers: headers(),
    body: JSON.stringify({ question }),
  });
  return parseJson<VectorChatResponse>(res);
}
