import type { GitConnectRequest } from "../types";

const KEY = "docviz_git_connect_request";

/**
 * Guarda los parámetros usados en POST /connect/git para poder reconectar la sesión
 * del servidor tras F5 o reinicio del backend (sessionStorage, pestaña actual).
 */
export function saveGitConnectRequest(body: GitConnectRequest): void {
  try {
    sessionStorage.setItem(KEY, JSON.stringify(body));
  } catch {
    /* ignore */
  }
}

export function loadGitConnectRequest(): GitConnectRequest | null {
  try {
    const raw = sessionStorage.getItem(KEY);
    if (!raw) return null;
    const o = JSON.parse(raw) as GitConnectRequest;
    if (!o || typeof o.mode !== "string") return null;
    return o;
  } catch {
    return null;
  }
}

export function clearGitConnectRequest(): void {
  try {
    sessionStorage.removeItem(KEY);
  } catch {
    /* ignore */
  }
}

export function hasSavedGitConnectRequest(): boolean {
  return loadGitConnectRequest() != null;
}
