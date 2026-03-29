import type {
  ConnectResponse,
  FileContentResponse,
  GitConnectRequest,
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
  if (v !== undefined && v !== "") {
    return v.replace(/\/$/, "");
  }
  return "/api";
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

export async function vectorChat(question: string): Promise<VectorChatResponse> {
  const res = await fetch(`${apiBase()}/vector/chat`, {
    method: "POST",
    headers: headers(),
    body: JSON.stringify({ question }),
  });
  return parseJson<VectorChatResponse>(res);
}
