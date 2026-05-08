import { randomUuid } from "../util/randomUuid";

import type {
  CellRepoRequestBody,
  CellRequestBody,
  CellResponse,
  CellRepoResponse,
  CellRepoUrlHint,
  GitConnectionMode,
  ChatHistoryEntry,
  ConnectResponse,
  DeleteImpactResponse,
  FolderStructureDto,
  FileContentResponse,
  GitConnectRequest,
  IngestProgressEvent,
  SupportMarkdownObjectDto,
  SupportMarkdownUploadResponse,
  TagsResponse,
  TaskArtifactRestoreResponse,
  TaskContinueResponse,
  TaskCreateRequest,
  TaskResponse,
  WorkAreaS3ObjectDto,
  RagChatTurnResponse,
  VectorChatResponse,
  VectorClearResponse,
  VectorIngestResponse,
  WorkAreaChangeBlock,
  WorkAreaFileProposal,
} from "../types";

export const USER_HEADER = "X-DocViz-User";
/** Opcional: código HU para sincronizar borradores / workarea en S3 (REST). */
export const TASK_HU_HEADER = "X-DocViz-Task-Hu";
/** Opcional: nombre de célula para las mismas rutas S3. */
export const CELL_HEADER = "X-DocViz-Cell";
/** Debe coincidir con el backend (cabecera de rol efectivo para DocViz). */
export const DOCVIZ_ROLE_HEADER = "X-DocViz-Role";
export const ROLE_ADMINISTRATOR = "ROLE_ADMINISTRATOR";
export const ROLE_SUPPORT = "ROLE_SUPPORT";

const storedKey = "docviz_user";
const accessTokenKey = "docviz_access_token";
const refreshTokenKey = "docviz_refresh_token";
const roleStorageKey = "docviz_role";

export function getUserId(): string {
  return localStorage.getItem(storedKey) ?? "";
}

export function setUserId(id: string): void {
  localStorage.setItem(storedKey, id.trim());
}

export function clearUserId(): void {
  localStorage.removeItem(storedKey);
}

/**
 * Si CELL_REPO_READY llega con archivos/chunks en 0 pero hubo un DONE previo en el mismo stream,
 * conservar los conteos del DONE (p. ej. lectura BD desfasada o proxy que agrupa líneas NDJSON).
 */
function mergeReadyAndDoneIngestCounts(
  lastReady: IngestProgressEvent,
  lastDone: IngestProgressEvent | null,
): { files: number | null; chunks: number | null; skipped: string[] | undefined | null } {
  const rf = lastReady.filesProcessed;
  const rc = lastReady.chunksIndexed;
  const df = lastDone?.filesProcessed;
  const dc = lastDone?.chunksIndexed;
  const files =
    rf != null && rf > 0 ? rf : df != null && df > 0 ? df : rf ?? df ?? null;
  const chunks =
    rc != null && rc > 0 ? rc : dc != null && dc > 0 ? dc : rc ?? dc ?? null;
  const skipped =
    lastReady.skipped != null && lastReady.skipped.length > 0
      ? lastReady.skipped
      : lastDone?.skipped ?? null;
  return { files, chunks, skipped };
}

function parseJwtRole(jwt: string): string {
  try {
    const parts = jwt.split(".");
    if (parts.length < 2) return ROLE_ADMINISTRATOR;
    const payload = JSON.parse(atob(parts[1])) as { role?: string; claims?: { role?: string } };
    const r = payload.role ?? payload.claims?.role;
    if (typeof r === "string" && r.trim()) return r.trim();
    return ROLE_ADMINISTRATOR;
  } catch {
    return ROLE_ADMINISTRATOR;
  }
}

/** Rol DocViz persistido (JWT security); por defecto administrador. */
export function getDocVizRole(): string {
  try {
    const r = localStorage.getItem(roleStorageKey);
    if (r != null && r.trim()) return r.trim();
    const jwt = getAccessToken();
    return jwt ? parseJwtRole(jwt) : ROLE_ADMINISTRATOR;
  } catch {
    return ROLE_ADMINISTRATOR;
  }
}

export function isSupportRole(): boolean {
  return getDocVizRole() === ROLE_SUPPORT;
}

export function getAccessToken(): string {
  return localStorage.getItem(accessTokenKey) ?? "";
}

export function getRefreshToken(): string {
  return localStorage.getItem(refreshTokenKey) ?? "";
}

/** Persiste usuario DocViz (cabecera), tokens del micro de security y rol deducido del JWT. */
export function setAuthSession(username: string, accessJwt: string, refreshJwt: string): void {
  setUserId(username);
  localStorage.setItem(accessTokenKey, accessJwt);
  localStorage.setItem(refreshTokenKey, refreshJwt);
  localStorage.setItem(roleStorageKey, parseJwtRole(accessJwt));
}

export function clearAuthSession(): void {
  clearUserId();
  localStorage.removeItem(accessTokenKey);
  localStorage.removeItem(refreshTokenKey);
  localStorage.removeItem(roleStorageKey);
}

function securityBase(): string {
  const fromRuntime =
    typeof window !== "undefined"
      ? (window as Window & { __DOCVIZ_SECURITY_BASE__?: string }).__DOCVIZ_SECURITY_BASE__
      : undefined;
  if (fromRuntime != null && String(fromRuntime).trim() !== "") {
    return String(fromRuntime).trim().replace(/\/$/, "");
  }
  const v = import.meta.env.VITE_SECURITY_URL;
  if (v === undefined || String(v).trim() === "") {
    throw new Error(
      "Falta la base del security: en Docker define SECURITY_URL (o VITE_SECURITY_URL en build; p. ej. /security-api con proxy).",
    );
  }
  return String(v).trim().replace(/\/$/, "");
}

function parseJwtSub(jwt: string): string {
  try {
    const parts = jwt.split(".");
    if (parts.length < 2) return "";
    const payload = JSON.parse(atob(parts[1])) as { sub?: string };
    return payload.sub?.trim() ?? "";
  } catch {
    return "";
  }
}

export type SecurityAuthToken = {
  jwt: string;
  jwtRefresh: string;
  available: boolean;
  username?: string | null;
};

export type RegisterUserResponse = {
  username: string;
  email: string;
  phone: string | null;
  roleName: string;
  operationNames: string[];
  jwt: string;
  jwtRefresh: string;
};

/** Aplica tokens del security y fija X-DocViz-User al username (sub del JWT o campo username). */
export function applyAuthFromSecurityTokens(tokens: SecurityAuthToken): void {
  if (!tokens.available || !tokens.jwt) {
    throw new Error("Respuesta de autenticación inválida.");
  }
  const name =
    (tokens.username && tokens.username.trim()) || parseJwtSub(tokens.jwt) || "";
  if (!name) {
    throw new Error("No se pudo determinar el usuario tras el login.");
  }
  setAuthSession(name, tokens.jwt, tokens.jwtRefresh);
}

/** Login contra back-security: POST .../api/v1/auth/login (rol opcional). */
export async function loginSecurity(body: {
  usernameOrEmail: string;
  password: string;
  role?: string | null;
}): Promise<SecurityAuthToken> {
  const payload: Record<string, unknown> = {
    usernameOrEmail: body.usernameOrEmail.trim(),
    password: body.password,
  };
  if (body.role != null && String(body.role).trim() !== "") {
    payload.role = String(body.role).trim();
  }
  const res = await fetch(`${securityBase()}/api/v1/auth/login`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "X-JWT-Algorithm": "HS256",
    },
    body: JSON.stringify(payload),
  });
  return parseJson<SecurityAuthToken>(res);
}

/** Registro de cliente: POST .../api/v1/customers */
export async function registerSecurity(body: {
  username: string;
  email: string;
  password: string;
  phone?: string;
  roleName?: string;
}): Promise<RegisterUserResponse> {
  const payload: Record<string, unknown> = {
    username: body.username.trim(),
    email: body.email.trim(),
    password: body.password,
  };
  if (body.phone != null && body.phone.trim() !== "") {
    payload.phone = body.phone.trim();
  }
  if (body.roleName != null && body.roleName.trim() !== "") {
    payload.roleName = body.roleName.trim();
  }
  const res = await fetch(`${securityBase()}/api/v1/customers`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "X-JWT-Algorithm": "HS256",
    },
    body: JSON.stringify(payload),
  });
  return parseJson<RegisterUserResponse>(res);
}

/** Revoca JWT en el micro de security (si hay access token guardado). */
export async function logoutSecurity(): Promise<void> {
  const access = getAccessToken();
  const refresh = getRefreshToken();
  if (!access) return;
  const res = await fetch(`${securityBase()}/api/v1/auth/logout`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "X-JWT-Algorithm": "HS256",
    },
    body: JSON.stringify({ accessToken: access, refreshToken: refresh || null }),
  });
  if (!res.ok) {
    const text = await res.text();
    let msg = text || res.statusText;
    try {
      const j = JSON.parse(text) as { error?: string; message?: string };
      msg = j.message ?? j.error ?? msg;
    } catch {
      /* ignore */
    }
    throw new Error(msg);
  }
}

function apiBase(): string {
  const fromRuntime =
    typeof window !== "undefined"
      ? (window as Window & { __DOCVIZ_API_BASE__?: string }).__DOCVIZ_API_BASE__
      : undefined;
  if (fromRuntime != null && String(fromRuntime).trim() !== "") {
    return String(fromRuntime).trim().replace(/\/$/, "");
  }
  const v = import.meta.env.VITE_API_URL;
  if (v === undefined || v === "") {
    throw new Error(
      "Falta la URL del API: en Docker define BACKEND_URL (Railway); en local, VITE_API_URL en .env (p. ej. /api con el proxy de Vite).",
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
      msg = j.message ?? j.error ?? msg;
    } catch {
      /* ignore */
    }
    throw new Error(msg);
  }
  if (!text) return {} as T;
  return JSON.parse(text) as T;
}

/** Cabeceras opcionales alineadas con el filtro HTTP del backend (borradores, workarea). */
export function docvizTaskContextHeaders(huCode?: string | null, cellLabel?: string | null): HeadersInit {
  const o: Record<string, string> = {};
  if (huCode?.trim()) o[TASK_HU_HEADER] = huCode.trim();
  if (cellLabel?.trim()) o[CELL_HEADER] = cellLabel.trim();
  return o;
}

function headers(extra?: HeadersInit): HeadersInit {
  const uid = getUserId();
  if (!uid) {
    throw new Error("Falta el identificador de usuario (DocViz).");
  }
  return {
    "Content-Type": "application/json",
    [USER_HEADER]: uid,
    [DOCVIZ_ROLE_HEADER]: getDocVizRole(),
    ...extra,
  };
}

/** Cabeceras sin Content-Type (p. ej. FormData con boundary). */
function headersMultipart(): HeadersInit {
  const uid = getUserId();
  if (!uid) {
    throw new Error("Falta el identificador de usuario (DocViz).");
  }
  return { [USER_HEADER]: uid, [DOCVIZ_ROLE_HEADER]: getDocVizRole() };
}

export async function connectGit(body: GitConnectRequest): Promise<ConnectResponse> {
  const res = await fetch(`${apiBase()}/connect/git`, {
    method: "POST",
    headers: headers(),
    body: JSON.stringify(body),
  });
  return parseJson<ConnectResponse>(res);
}

export async function fetchCells(): Promise<CellResponse[]> {
  const res = await fetch(`${apiBase()}/cells`, { headers: headers() });
  return parseJson<CellResponse[]>(res);
}

export async function fetchCellRepos(cellId: number): Promise<CellRepoResponse[]> {
  const res = await fetch(`${apiBase()}/cells/${cellId}/repos`, { headers: headers() });
  return parseJson<CellRepoResponse[]>(res);
}

export async function createTask(body: TaskCreateRequest): Promise<TaskResponse> {
  const res = await fetch(`${apiBase()}/tasks`, {
    method: "POST",
    headers: headers(),
    body: JSON.stringify(body),
  });
  return parseJson<TaskResponse>(res);
}

/** Lista tareas; con cellId filtra por célula (admin: todas en la celda; soporte: las del usuario). */
export async function fetchTasks(cellId?: number): Promise<TaskResponse[]> {
  const q = cellId != null ? `?cellId=${encodeURIComponent(String(cellId))}` : "";
  const res = await fetch(`${apiBase()}/tasks${q}`, { headers: headers() });
  return parseJson<TaskResponse[]>(res);
}

export async function getTask(id: number): Promise<TaskResponse> {
  const res = await fetch(`${apiBase()}/tasks/${id}`, { headers: headers() });
  return parseJson<TaskResponse>(res);
}

export async function continueTask(taskId: number): Promise<TaskContinueResponse> {
  const res = await fetch(`${apiBase()}/tasks/continue`, {
    method: "POST",
    headers: headers(),
    body: JSON.stringify({ taskId }),
  });
  return parseJson<TaskContinueResponse>(res);
}

export async function listSupportMarkdownObjects(cellRepoId: number): Promise<SupportMarkdownObjectDto[]> {
  const q = encodeURIComponent(String(cellRepoId));
  const res = await fetch(`${apiBase()}/support/markdown/objects?cellRepoId=${q}`, { headers: headers() });
  if (res.status === 404) return [];
  return parseJson<SupportMarkdownObjectDto[]>(res);
}

/** Descarga texto desde URL presignada S3 (GET /support/markdown/object eliminado). */
export async function fetchTextFromPresignedUrl(url: string, init?: { signal?: AbortSignal }): Promise<string> {
  const res = await fetch(url, { method: "GET", signal: init?.signal });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(text || res.statusText);
  }
  return res.text();
}

export async function adminCreateCell(body: CellRequestBody): Promise<CellResponse> {
  const res = await fetch(`${apiBase()}/admin/cells`, {
    method: "POST",
    headers: headers(),
    body: JSON.stringify(body),
  });
  return parseJson<CellResponse>(res);
}

export async function adminUpdateCell(id: number, body: CellRequestBody): Promise<CellResponse> {
  const res = await fetch(`${apiBase()}/admin/cells/${id}`, {
    method: "PUT",
    headers: headers(),
    body: JSON.stringify(body),
  });
  return parseJson<CellResponse>(res);
}

export async function adminDeleteCell(id: number): Promise<void> {
  const res = await fetch(`${apiBase()}/admin/cells/${id}`, {
    method: "DELETE",
    headers: headers(),
  });
  if (!res.ok) {
    const text = await res.text();
    let msg = text || res.statusText;
    try {
      const j = JSON.parse(text) as { error?: string; message?: string };
      msg = j.message ?? j.error ?? msg;
    } catch {
      /* ignore */
    }
    throw new Error(msg);
  }
}

export async function adminFetchCellDeleteImpact(cellId: number): Promise<DeleteImpactResponse> {
  const res = await fetch(`${apiBase()}/admin/cells/${cellId}/delete-impact`, { headers: headers() });
  return parseJson<DeleteImpactResponse>(res);
}

export async function adminFetchRepoDeleteImpact(cellId: number, repoId: number): Promise<DeleteImpactResponse> {
  const res = await fetch(`${apiBase()}/admin/cells/${cellId}/repos/${repoId}/delete-impact`, {
    headers: headers(),
  });
  return parseJson<DeleteImpactResponse>(res);
}

/** Nombre y namespace sugeridos; si el URL ya existe en BD, reutiliza los guardados. */
export async function adminRepoUrlHint(params: {
  url?: string;
  localPath?: string;
  mode: GitConnectionMode;
}): Promise<CellRepoUrlHint> {
  const q = new URLSearchParams();
  q.set("mode", params.mode);
  if (params.url != null && params.url.trim() !== "") q.set("url", params.url.trim());
  if (params.localPath != null && params.localPath.trim() !== "") q.set("localPath", params.localPath.trim());
  const res = await fetch(`${apiBase()}/admin/cells/hints/repo-url?${q.toString()}`, { headers: headers() });
  return parseJson<CellRepoUrlHint>(res);
}

export async function adminCreateRepo(cellId: number, body: CellRepoRequestBody): Promise<CellRepoResponse> {
  const res = await fetch(`${apiBase()}/admin/cells/${cellId}/repos`, {
    method: "POST",
    headers: headers(),
    body: JSON.stringify(body),
  });
  return parseJson<CellRepoResponse>(res);
}

/**
 * Crea repo en la célula con NDJSON de progreso (archivos, chunks) y evento final CELL_REPO_READY.
 * Si el backend no expone /repos/stream (404), delega en {@link adminCreateRepo}.
 */
export async function adminCreateRepoStream(
  cellId: number,
  body: CellRepoRequestBody,
  onProgress: (ev: IngestProgressEvent) => void,
  init?: { signal?: AbortSignal },
): Promise<CellRepoResponse> {
  const res = await fetch(`${apiBase()}/admin/cells/${cellId}/repos/stream`, {
    method: "POST",
    headers: {
      ...headers(),
      Accept: "application/x-ndjson, application/json;q=0.9, */*;q=0.1",
      "Content-Type": "application/json",
    },
    body: JSON.stringify(body),
    signal: init?.signal,
  });
  if (res.status === 404) {
    onProgress({ phase: "START", totalFiles: 0, filesProcessed: 0, chunksIndexed: 0 });
    const r = await adminCreateRepo(cellId, body);
    onProgress({
      phase: "CELL_REPO_READY",
      cellRepoId: r.id,
      displayName: r.displayName,
      filesProcessed: r.lastIngestFiles ?? 0,
      chunksIndexed: r.lastIngestChunks ?? 0,
      namespace: r.vectorNamespace ?? "",
      linkedWithoutReindex: r.linkedWithoutReindex,
    });
    return r;
  }
  if (!res.ok) {
    const text = await res.text();
    let msg = text || res.statusText;
    try {
      const j = JSON.parse(text) as { error?: string; message?: string };
      msg = j.message ?? j.error ?? msg;
    } catch {
      /* ignore */
    }
    throw new Error(msg);
  }
  const reader = res.body?.getReader();
  if (!reader) {
    throw new Error("Respuesta sin cuerpo legible");
  }
  const decoder = new TextDecoder();
  let buffer = "";
  let readyId: number | null = null;

  function consumeLine(trimmed: string): void {
    if (!trimmed) return;
    const ev = JSON.parse(trimmed) as IngestProgressEvent;
    onProgress(ev);
    if (ev.phase === "ERROR") {
      throw new Error(ev.error ?? "Error al crear el repositorio");
    }
    if (ev.phase === "CELL_REPO_READY" && ev.cellRepoId != null) {
      readyId = ev.cellRepoId;
    }
  }

  while (true) {
    const { done, value } = await reader.read();
    if (done) {
      buffer += decoder.decode();
      break;
    }
    buffer += decoder.decode(value, { stream: true });
    const lines = buffer.split("\n");
    buffer = lines.pop() ?? "";
    for (const line of lines) {
      consumeLine(line.trim());
    }
  }
  const tail = buffer.trim();
  if (tail) {
    consumeLine(tail);
  }

  const repos = await fetchCellRepos(cellId);
  const found =
    readyId != null ? repos.find((r) => r.id === readyId) : repos.length > 0 ? repos[repos.length - 1] : undefined;
  if (!found) {
    throw new Error("No se pudo confirmar el repositorio creado.");
  }
  return found;
}

/**
 * Indexa un repositorio sin célula (NDJSON). Tras “Guardar” se asigna con {@link adminAssignReposToCell}.
 */
export async function adminIndexRepoStream(
  body: CellRepoRequestBody,
  onProgress: (ev: IngestProgressEvent) => void,
  init?: { signal?: AbortSignal },
): Promise<CellRepoResponse> {
  const res = await fetch(`${apiBase()}/admin/cells/pending/index/stream`, {
    method: "POST",
    headers: {
      ...headers(),
      Accept: "application/x-ndjson, application/json;q=0.9, */*;q=0.1",
      "Content-Type": "application/json",
    },
    body: JSON.stringify(body),
    signal: init?.signal,
  });
  if (!res.ok) {
    const text = await res.text();
    let msg = text || res.statusText;
    try {
      const j = JSON.parse(text) as { error?: string; message?: string };
      msg = j.message ?? j.error ?? msg;
    } catch {
      /* ignore */
    }
    throw new Error(msg);
  }
  const reader = res.body?.getReader();
  if (!reader) {
    throw new Error("Respuesta sin cuerpo legible");
  }
  const decoder = new TextDecoder();
  let buffer = "";
  let lastReady: IngestProgressEvent | null = null;
  let lastDone: IngestProgressEvent | null = null;

  function consumeLine(trimmed: string): void {
    if (!trimmed) return;
    const ev = JSON.parse(trimmed) as IngestProgressEvent;
    onProgress(ev);
    if (ev.phase === "ERROR") {
      throw new Error(ev.error ?? "Error al indexar el repositorio");
    }
    if (ev.phase === "DONE") {
      lastDone = ev;
    }
    if (ev.phase === "CELL_REPO_READY") {
      lastReady = ev;
    }
  }

  while (true) {
    const { done, value } = await reader.read();
    if (done) {
      buffer += decoder.decode();
      break;
    }
    buffer += decoder.decode(value, { stream: true });
    const lines = buffer.split("\n");
    buffer = lines.pop() ?? "";
    for (const line of lines) {
      consumeLine(line.trim());
    }
  }
  const tail = buffer.trim();
  if (tail) {
    consumeLine(tail);
  }

  if (!lastReady || lastReady.cellRepoId == null) {
    throw new Error("No se recibió confirmación del repositorio indexado.");
  }
  const merged = mergeReadyAndDoneIngestCounts(lastReady, lastDone);
  return {
    id: lastReady.cellRepoId,
    cellId: null,
    displayName: lastReady.displayName ?? "",
    repositoryUrl: body.repositoryUrl,
    connectionMode: body.connectionMode,
    gitUsername: body.gitUsername ?? null,
    hasCredential: !!(body.credentialPlain && body.credentialPlain.length > 0),
    localPath: body.localPath ?? null,
    tagsCsv: body.tagsCsv ?? null,
    vectorNamespace: lastReady.namespace ?? null,
    active: true,
    createdAt: null,
    updatedAt: null,
    lastIngestAt: null,
    lastIngestFiles: merged.files,
    lastIngestChunks: merged.chunks,
    lastIngestSkipped: merged.skipped ?? null,
    linkedWithoutReindex: lastReady.linkedWithoutReindex,
  };
}

export async function adminAssignReposToCell(cellId: number, repoIds: number[]): Promise<CellRepoResponse[]> {
  const res = await fetch(`${apiBase()}/admin/cells/${cellId}/repos/assign`, {
    method: "POST",
    headers: {
      ...headers(),
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ repoIds }),
  });
  return parseJson<CellRepoResponse[]>(res);
}

export async function adminDeletePendingRepo(repoId: number): Promise<void> {
  const res = await fetch(`${apiBase()}/admin/cells/pending/${repoId}`, {
    method: "DELETE",
    headers: headers(),
  });
  if (!res.ok) {
    const text = await res.text();
    let msg = text || res.statusText;
    try {
      const j = JSON.parse(text) as { error?: string; message?: string };
      msg = j.message ?? j.error ?? msg;
    } catch {
      /* ignore */
    }
    throw new Error(msg);
  }
}

export async function adminDeleteRepo(cellId: number, repoId: number): Promise<void> {
  const res = await fetch(`${apiBase()}/admin/cells/${cellId}/repos/${repoId}`, {
    method: "DELETE",
    headers: headers(),
  });
  if (!res.ok) {
    const text = await res.text();
    let msg = text || res.statusText;
    try {
      const j = JSON.parse(text) as { error?: string; message?: string };
      msg = j.message ?? j.error ?? msg;
    } catch {
      /* ignore */
    }
    throw new Error(msg);
  }
}

/** Asegura arrays y anidación aunque el JSON venga incompleto. */
function normalizeFolderStructure(raw: unknown): FolderStructureDto {
  if (raw == null || typeof raw !== "object") {
    return { folder: "", archivos: [], folders: [] };
  }
  const o = raw as Record<string, unknown>;
  const folder = typeof o.folder === "string" ? o.folder : "";
  const archivos = Array.isArray(o.archivos)
    ? (o.archivos.filter((x) => typeof x === "string") as string[])
    : [];
  const foldersRaw = Array.isArray(o.folders) ? o.folders : [];
  const folders = foldersRaw.map((f) => normalizeFolderStructure(f));
  return { folder, archivos, folders };
}

export async function adminFetchRepoTree(cellId: number, repoId: number): Promise<FolderStructureDto> {
  const res = await fetch(`${apiBase()}/admin/cells/${cellId}/repos/${repoId}/tree`, { headers: headers() });
  const data = await parseJson<unknown>(res);
  return normalizeFolderStructure(data);
}

export async function adminFetchRepoFile(cellId: number, repoId: number, path: string): Promise<FileContentResponse> {
  const q = encodeURIComponent(path);
  const res = await fetch(`${apiBase()}/admin/cells/${cellId}/repos/${repoId}/file?path=${q}`, { headers: headers() });
  return parseJson<FileContentResponse>(res);
}

export async function adminFetchPendingRepoTree(repoId: number): Promise<FolderStructureDto> {
  const res = await fetch(`${apiBase()}/admin/cells/pending/${repoId}/tree`, { headers: headers() });
  const data = await parseJson<unknown>(res);
  return normalizeFolderStructure(data);
}

export async function adminFetchPendingRepoFile(repoId: number, path: string): Promise<FileContentResponse> {
  const q = encodeURIComponent(path);
  const res = await fetch(`${apiBase()}/admin/cells/pending/${repoId}/file?path=${q}`, { headers: headers() });
  return parseJson<FileContentResponse>(res);
}

export async function adminUploadCellSupportMarkdown(
  cellId: number,
  repoId: number,
  file: File,
  huCode: string,
  huTitle: string,
): Promise<SupportMarkdownUploadResponse> {
  const fd = new FormData();
  fd.append("file", file, file.name);
  fd.append("huCode", huCode);
  fd.append("huTitle", huTitle);
  const res = await fetch(`${apiBase()}/admin/cells/${cellId}/repos/${repoId}/support/markdown`, {
    method: "POST",
    headers: headersMultipart(),
    body: fd,
  });
  return parseJson<SupportMarkdownUploadResponse>(res);
}

export async function adminUploadPendingSupportMarkdown(
  repoId: number,
  file: File,
  huCode: string,
  huTitle: string,
): Promise<SupportMarkdownUploadResponse> {
  const fd = new FormData();
  fd.append("file", file, file.name);
  fd.append("huCode", huCode);
  fd.append("huTitle", huTitle);
  const res = await fetch(`${apiBase()}/admin/cells/pending/${repoId}/support/markdown`, {
    method: "POST",
    headers: headersMultipart(),
    body: fd,
  });
  return parseJson<SupportMarkdownUploadResponse>(res);
}

export async function adminDeleteCellSupportMarkdown(cellId: number, repoId: number, fileName: string): Promise<void> {
  const q = encodeURIComponent(fileName);
  const res = await fetch(`${apiBase()}/admin/cells/${cellId}/repos/${repoId}/support/markdown?fileName=${q}`, {
    method: "DELETE",
    headers: headers(),
  });
  if (!res.ok) {
    const text = await res.text();
    let msg = text || res.statusText;
    try {
      const j = JSON.parse(text) as { error?: string; message?: string };
      msg = j.message ?? j.error ?? msg;
    } catch {
      /* ignore */
    }
    throw new Error(msg);
  }
}

export async function adminDeletePendingSupportMarkdown(repoId: number, fileName: string): Promise<void> {
  const q = encodeURIComponent(fileName);
  const res = await fetch(`${apiBase()}/admin/cells/pending/${repoId}/support/markdown?fileName=${q}`, {
    method: "DELETE",
    headers: headers(),
  });
  if (!res.ok) {
    const text = await res.text();
    let msg = text || res.statusText;
    try {
      const j = JSON.parse(text) as { error?: string; message?: string };
      msg = j.message ?? j.error ?? msg;
    } catch {
      /* ignore */
    }
    throw new Error(msg);
  }
}

export async function adminUpdateCellSupportMarkdown(
  cellId: number,
  repoId: number,
  fileName: string,
  content: string,
): Promise<SupportMarkdownUploadResponse> {
  const res = await fetch(`${apiBase()}/admin/cells/${cellId}/repos/${repoId}/support/markdown`, {
    method: "PUT",
    headers: {
      ...headers(),
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ fileName, content }),
  });
  return parseJson<SupportMarkdownUploadResponse>(res);
}

export async function adminUpdatePendingSupportMarkdown(
  repoId: number,
  fileName: string,
  content: string,
): Promise<SupportMarkdownUploadResponse> {
  const res = await fetch(`${apiBase()}/admin/cells/pending/${repoId}/support/markdown`, {
    method: "PUT",
    headers: {
      ...headers(),
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ fileName, content }),
  });
  return parseJson<SupportMarkdownUploadResponse>(res);
}

/** Nombre del repo desde URL HTTPS terminada en `.git` (segmento tras el último `/`). */
export function parseGitRepoNameFromHttpsUrl(url: string): string | null {
  const t = url.trim();
  if (t.length < 5) return null;
  const lower = t.toLowerCase();
  if (!lower.endsWith(".git")) return null;
  const noGit = t.slice(0, -4);
  const slash = Math.max(noGit.lastIndexOf("/"), noGit.lastIndexOf("\\"));
  const seg = slash >= 0 ? noGit.slice(slash + 1) : noGit;
  const name = seg.replace(/\.git$/i, "").trim();
  return name || null;
}

/** Namespace tipo `nombre-uuid` (alineado con el backend). */
export function newVectorNamespaceFromRepoName(name: string): string {
  const u = randomUuid();
  const safe = name.replace(/[^a-zA-Z0-9._-]/g, "_").replace(/_+/g, "_").slice(0, 200) || "repo";
  return `${safe}-${u}`.slice(0, 500);
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

/** Sube Markdown de soporte a S3 y genera embeddings (requiere DOCVIZ_SUPPORT_ENABLED en el backend). */
/** Se lanza cuando el backend no expone POST /support/markdown (p. ej. DOCVIZ_SUPPORT_ENABLED=false). */
export const SUPPORT_UPLOAD_API_UNAVAILABLE = "SUPPORT_UPLOAD_API_UNAVAILABLE";

export async function uploadSupportMarkdown(
  file: File,
  init?: { signal?: AbortSignal },
): Promise<SupportMarkdownUploadResponse> {
  const form = new FormData();
  form.append("file", file, file.name);
  const res = await fetch(`${apiBase()}/support/markdown`, {
    method: "POST",
    headers: headersMultipart(),
    body: form,
    signal: init?.signal,
  });
  if (res.status === 404) {
    throw new Error(SUPPORT_UPLOAD_API_UNAVAILABLE);
  }
  return parseJson<SupportMarkdownUploadResponse>(res);
}

export async function deleteSupportMarkdown(fileName: string): Promise<void> {
  const q = encodeURIComponent(fileName);
  const res = await fetch(`${apiBase()}/support/markdown?fileName=${q}`, {
    method: "DELETE",
    headers: headers(),
  });
  await parseJson<Record<string, unknown>>(res);
}

export async function vectorIngest(init?: { signal?: AbortSignal }): Promise<VectorIngestResponse> {
  const res = await fetch(`${apiBase()}/vector/ingest`, {
    method: "POST",
    headers: headers(),
    signal: init?.signal,
  });
  return parseJson<VectorIngestResponse>(res);
}

export type WorkAreaRequestInit = { signal?: AbortSignal; taskHuCode?: string; cellLabel?: string };

/** Restaura borradores y workarea desde S3 al clon (POST /vector/work-area/restore-s3). Requiere sesión Git. */
/** Lista objetos S3 (borradores o workarea) con URL presignada. Requiere cabecera HU. */
export async function listWorkAreaS3Objects(
  kind: "borradores" | "workarea",
  init?: WorkAreaRequestInit,
): Promise<WorkAreaS3ObjectDto[]> {
  const q = encodeURIComponent(kind);
  const res = await fetch(`${apiBase()}/vector/work-area/s3-objects?kind=${q}`, {
    method: "GET",
    headers: headers(docvizTaskContextHeaders(init?.taskHuCode, init?.cellLabel)),
    signal: init?.signal,
  });
  if (res.status === 404) return [];
  return parseJson<WorkAreaS3ObjectDto[]>(res);
}

/** GET /vector/work-area/s3-artifacts: borradores + workarea; query userId y taskHu (deben coincidir con sesión y cabecera HU). */
export async function fetchWorkAreaS3Artifacts(
  userId: string,
  taskHu: string,
  init?: WorkAreaRequestInit,
): Promise<WorkAreaS3ObjectDto[]> {
  const u = encodeURIComponent(userId.trim());
  const t = encodeURIComponent(taskHu.trim());
  const res = await fetch(`${apiBase()}/vector/work-area/s3-artifacts?userId=${u}&taskHu=${t}`, {
    method: "GET",
    headers: headers(docvizTaskContextHeaders(init?.taskHuCode ?? taskHu, init?.cellLabel)),
    signal: init?.signal,
  });
  if (res.status === 404) return [];
  return parseJson<WorkAreaS3ObjectDto[]>(res);
}

/** GET /vector/work-area/s3-artifact-body: texto UTF-8 (mismo origen que el API; evita CORS con LocalStack). */
export async function fetchWorkAreaS3ArtifactBody(
  bucket: string,
  objectKey: string,
  init?: WorkAreaRequestInit,
): Promise<string> {
  const b = encodeURIComponent(bucket.trim());
  const k = encodeURIComponent(objectKey.trim());
  const res = await fetch(`${apiBase()}/vector/work-area/s3-artifact-body?bucket=${b}&key=${k}`, {
    method: "GET",
    headers: headers(docvizTaskContextHeaders(init?.taskHuCode, init?.cellLabel)),
    signal: init?.signal,
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(text || res.statusText);
  }
  return res.text();
}

export async function deleteWorkAreaS3Artifact(
  bucket: string,
  objectKey: string,
  init?: WorkAreaRequestInit,
): Promise<void> {
  const b = encodeURIComponent(bucket.trim());
  const k = encodeURIComponent(objectKey.trim());
  const res = await fetch(`${apiBase()}/vector/work-area/s3-artifact?bucket=${b}&key=${k}`, {
    method: "DELETE",
    headers: headers(docvizTaskContextHeaders(init?.taskHuCode, init?.cellLabel)),
    signal: init?.signal,
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(text || res.statusText);
  }
}

/** POST /vector/work-area/s3-workarea-save — persiste en S3 y reindexa (pgvector). */
export async function saveWorkAreaS3WorkareaAndReindex(
  body: { objectKey: string; content: string },
  init?: WorkAreaRequestInit,
): Promise<VectorIngestResponse> {
  const res = await fetch(`${apiBase()}/vector/work-area/s3-workarea-save`, {
    method: "POST",
    headers: {
      ...headers(docvizTaskContextHeaders(init?.taskHuCode, init?.cellLabel)),
      "Content-Type": "application/json",
    },
    body: JSON.stringify(body),
    signal: init?.signal,
  });
  return parseJson<VectorIngestResponse>(res);
}

/** POST /vector/work-area/s3-borrador-save — objeto en bucket borradores (sin reindexar). */
export async function saveWorkAreaS3BorradorContent(
  body: { objectKey: string; content: string },
  init?: WorkAreaRequestInit,
): Promise<void> {
  const res = await fetch(`${apiBase()}/vector/work-area/s3-borrador-save`, {
    method: "POST",
    headers: {
      ...headers(docvizTaskContextHeaders(init?.taskHuCode, init?.cellLabel)),
      "Content-Type": "application/json",
    },
    body: JSON.stringify(body),
    signal: init?.signal,
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(text || res.statusText);
  }
}

export async function restoreWorkAreaFromS3(init?: WorkAreaRequestInit): Promise<TaskArtifactRestoreResponse> {
  const res = await fetch(`${apiBase()}/vector/work-area/restore-s3`, {
    method: "POST",
    headers: headers(docvizTaskContextHeaders(init?.taskHuCode, init?.cellLabel)),
    signal: init?.signal,
  });
  return parseJson<TaskArtifactRestoreResponse>(res);
}

/** Indexa un borrador del área de trabajo en el namespace del repo conectado (POST /vector/work-area/ingest). */
export async function ingestWorkAreaFile(
  body: { fileName: string; content: string },
  init?: WorkAreaRequestInit,
): Promise<VectorIngestResponse> {
  const res = await fetch(`${apiBase()}/vector/work-area/ingest`, {
    method: "POST",
    headers: headers(docvizTaskContextHeaders(init?.taskHuCode, init?.cellLabel)),
    body: JSON.stringify(body),
    signal: init?.signal,
  });
  return parseJson<VectorIngestResponse>(res);
}

/** Aplica hunks aceptados (JSON del LLM), o escribe texto final con {@code finalContent} (evita errores de ancla). */
export async function applyWorkAreaReview(
  body: {
    sourcePath: string;
    draftVersion: number;
    changeBlocks?: WorkAreaChangeBlock[];
    accepted?: boolean[];
    /** Si viene relleno, el backend ignora hunks (mismo criterio que apply-final). */
    finalContent?: string;
  },
  init?: WorkAreaRequestInit,
): Promise<{ acceptedRelativePath: string }> {
  const res = await fetch(`${apiBase()}/vector/work-area/apply-review`, {
    method: "POST",
    headers: headers(docvizTaskContextHeaders(init?.taskHuCode, init?.cellLabel)),
    body: JSON.stringify(body),
    signal: init?.signal,
  });
  return parseJson<{ acceptedRelativePath: string }>(res);
}

/** Escribe *_vN.ext con el texto ya resuelto (vista merge de un solo bloque). */
export async function applyWorkAreaFinal(
  body: { sourcePath: string; draftVersion: number; finalContent: string },
  init?: WorkAreaRequestInit,
): Promise<{ acceptedRelativePath: string }> {
  const res = await fetch(`${apiBase()}/vector/work-area/apply-final`, {
    method: "POST",
    headers: headers(docvizTaskContextHeaders(init?.taskHuCode, init?.cellLabel)),
    body: JSON.stringify(body),
    signal: init?.signal,
  });
  return parseJson<{ acceptedRelativePath: string }>(res);
}

/** Acepta borrador .txt → escribe *_vN.ext y borra el .txt (no indexa). */
export async function acceptWorkAreaDraft(
  draftRelativePath: string,
  init?: WorkAreaRequestInit,
): Promise<{ acceptedRelativePath: string }> {
  const res = await fetch(`${apiBase()}/vector/work-area/draft/accept`, {
    method: "POST",
    headers: headers(docvizTaskContextHeaders(init?.taskHuCode, init?.cellLabel)),
    body: JSON.stringify({ draftRelativePath }),
    signal: init?.signal,
  });
  return parseJson<{ acceptedRelativePath: string }>(res);
}

/** Borrador resuelto desde la UI → escribe *_vN.ext, borra borrador local y en S3, sincroniza workarea S3. */
export async function finalizeWorkAreaDraft(
  body: { draftRelativePath: string; finalContent: string },
  init?: WorkAreaRequestInit,
): Promise<{ acceptedRelativePath: string }> {
  const res = await fetch(`${apiBase()}/vector/work-area/draft/finalize`, {
    method: "POST",
    headers: headers(docvizTaskContextHeaders(init?.taskHuCode, init?.cellLabel)),
    body: JSON.stringify(body),
    signal: init?.signal,
  });
  return parseJson<{ acceptedRelativePath: string }>(res);
}

export async function acceptAllWorkAreaDrafts(
  draftRelativePaths: string[],
  init?: WorkAreaRequestInit,
): Promise<{ acceptedRelativePaths: string[] }> {
  const res = await fetch(`${apiBase()}/vector/work-area/draft/accept-all`, {
    method: "POST",
    headers: headers(docvizTaskContextHeaders(init?.taskHuCode, init?.cellLabel)),
    body: JSON.stringify({ draftRelativePaths }),
    signal: init?.signal,
  });
  return parseJson<{ acceptedRelativePaths: string[] }>(res);
}

/** Lee el texto del borrador en el clon (GET) — misma ruta que DELETE, método distinto. */
export async function fetchWorkAreaDraftContent(
  draftRelativePath: string,
  init?: WorkAreaRequestInit,
): Promise<{ content: string }> {
  const q = encodeURIComponent(draftRelativePath);
  const res = await fetch(`${apiBase()}/vector/work-area/draft?path=${q}`, {
    method: "GET",
    headers: headers(docvizTaskContextHeaders(init?.taskHuCode, init?.cellLabel)),
    signal: init?.signal,
  });
  return parseJson<{ content: string }>(res);
}

export async function deleteWorkAreaDraft(path: string, init?: WorkAreaRequestInit): Promise<void> {
  const q = encodeURIComponent(path);
  const res = await fetch(`${apiBase()}/vector/work-area/draft?path=${q}`, {
    method: "DELETE",
    headers: headers(docvizTaskContextHeaders(init?.taskHuCode, init?.cellLabel)),
    signal: init?.signal,
  });
  await parseJson<Record<string, unknown>>(res);
}

/** Indexa un archivo ya aceptado en disco (p. ej. `customer-service/pom_v1.xml`). */
export async function indexWorkAreaFileFromPath(
  relativePath: string,
  init?: WorkAreaRequestInit,
): Promise<VectorIngestResponse> {
  const res = await fetch(`${apiBase()}/vector/work-area/index-file`, {
    method: "POST",
    headers: headers(docvizTaskContextHeaders(init?.taskHuCode, init?.cellLabel)),
    body: JSON.stringify({ relativePath }),
    signal: init?.signal,
  });
  return parseJson<VectorIngestResponse>(res);
}

/** Vacía el índice vectorial del repo actual (pgvector: borra filas del namespace; Pinecone: delete namespace). */
export async function vectorClearIndex(): Promise<VectorClearResponse> {
  const res = await fetch(`${apiBase()}/vector/index`, {
    method: "DELETE",
    headers: headers(),
  });
  return parseJson<VectorClearResponse>(res);
}

/**
 * Ingesta con streaming NDJSON: emite START, FILE, PROGRESS por archivo y DONE (o ERROR).
 */
export async function vectorIngestStream(
  onProgress: (ev: IngestProgressEvent) => void,
  init?: { signal?: AbortSignal },
): Promise<VectorIngestResponse> {
  const res = await fetch(`${apiBase()}/vector/ingest/stream`, {
    method: "POST",
    headers: {
      ...headers(),
      Accept: "application/x-ndjson, application/json;q=0.9, */*;q=0.1",
    },
    signal: init?.signal,
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
      msg = j.message ?? j.error ?? msg;
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
    const hint =
      import.meta.env.VITE_API_URL === "/api" || String(import.meta.env.VITE_API_URL ?? "").endsWith("/api")
        ? " Suele pasar si el proxy de Vite cierra la conexión larga: en frontend-sesion1/.env pon VITE_API_URL=http://127.0.0.1:8080 (CORS ya está permitido) y reinicia npm run dev."
        : "";
    throw new Error(
      "La ingesta terminó sin confirmación del servidor (no se recibió DONE en el stream)." + hint,
    );
  }
  return lastDone;
}

/** Ingesta sin NDJSON (sin barra de progreso por archivo); emite START + DONE al terminar. */
async function vectorIngestFallbackProgress(
  onProgress: (ev: IngestProgressEvent) => void,
): Promise<VectorIngestResponse> {
  onProgress({ phase: "START", totalFiles: 0 });
  const r = await vectorIngest({});
  onProgress({
    phase: "DONE",
    filesProcessed: r.filesProcessed,
    chunksIndexed: r.chunksIndexed,
    namespace: r.namespace,
    skipped: r.skipped,
  });
  return r;
}

export async function logoutSession(): Promise<void> {
  if (getUserId()) {
    const res = await fetch(`${apiBase()}/session/logout`, {
      method: "POST",
      headers: headers(),
    });
    if (!res.ok) {
      const text = await res.text();
      let msg = text || res.statusText;
      try {
        const j = JSON.parse(text) as { error?: string; message?: string };
        msg = j.message ?? j.error ?? msg;
      } catch {
        /* ignore */
      }
      throw new Error(msg);
    }
  }
  try {
    await logoutSecurity();
  } catch {
    /* revoke best-effort; la sesión local se borra igual */
  }
  clearAuthSession();
}

export async function vectorChat(question: string): Promise<VectorChatResponse> {
  const res = await fetch(`${apiBase()}/vector/chat`, {
    method: "POST",
    headers: headers(),
    body: JSON.stringify({ question }),
  });
  return parseJson<VectorChatResponse>(res);
}

const REST_RAG_DELTA_CHUNK = 480;

/**
 * Chat RAG vía POST {@code /vector/chat/rag-turn}. El historial se alinea con HU / {@code conversationId} / tarea / célula.
 * La respuesta llega completa; el cliente trocea el texto para mantener la sensación de escritura progresiva.
 */
export async function streamVectorChat(
  question: string,
  handlers: {
    onStart: (sources: string[]) => void;
    onDelta: (text: string) => void;
    /** Tras los deltas, el servidor puede enviar propuestas de área de trabajo (JSON parseado). */
    onProposals?: (proposals: WorkAreaFileProposal[]) => void;
  },
  /** Opcional: código HU, id de tarea (hilo principal en servidor), conversación explícita, célula. */
  options?: { taskHuCode?: string; conversationId?: string; taskId?: number; cellName?: string },
): Promise<void> {
  const uid = getUserId();
  if (!uid) {
    return Promise.reject(new Error("Falta el identificador de usuario (DocViz)."));
  }

  const body: Record<string, unknown> = { question };
  if (options?.taskHuCode?.trim()) body.taskHuCode = options.taskHuCode.trim();
  if (options?.conversationId?.trim()) body.conversationId = options.conversationId.trim();
  if (options?.taskId != null && Number.isFinite(options.taskId) && options.taskId > 0) {
    body.taskId = Math.trunc(options.taskId);
  }
  if (options?.cellName?.trim()) body.cellName = options.cellName.trim();

  const res = await fetch(`${apiBase()}/vector/chat/rag-turn`, {
    method: "POST",
    headers: headers(),
    body: JSON.stringify(body),
  });
  const data = await parseJson<RagChatTurnResponse>(res);
  handlers.onStart(data.sources ?? []);
  const ans = data.answer ?? "";
  for (let i = 0; i < ans.length; i += REST_RAG_DELTA_CHUNK) {
    handlers.onDelta(ans.slice(i, i + REST_RAG_DELTA_CHUNK));
  }
  if (data.proposals?.length && handlers.onProposals) {
    handlers.onProposals(data.proposals);
  }
}

export type FetchChatHistoryParams = {
  conversationId?: string;
  /** Con huCode: el servidor devuelve el hilo con menor N (principal). */
  taskId?: number;
  huCode?: string;
  /** Alineado con Firestore {@code usuario_celula_hu_taskId_N}. */
  cellName?: string;
};

/** Historial del chat en Firestore (mismo userId que X-DocViz-User). */
export async function fetchChatHistory(
  limit = 40,
  params?: string | FetchChatHistoryParams,
): Promise<{ entries: ChatHistoryEntry[]; resolvedConversationId?: string }> {
  const lim = encodeURIComponent(String(Math.min(Math.max(1, limit), 100)));
  let url = `${apiBase()}/vector/chat/history?limit=${lim}`;
  const p: FetchChatHistoryParams | undefined = typeof params === "string" ? { conversationId: params } : params;
  if (p?.taskId != null && p.taskId > 0 && p.huCode?.trim()) {
    url += `&taskId=${encodeURIComponent(String(p.taskId))}&huCode=${encodeURIComponent(p.huCode.trim())}`;
    if (p.cellName?.trim()) {
      url += `&cellName=${encodeURIComponent(p.cellName.trim())}`;
    }
  } else if (p?.conversationId?.trim()) {
    url += `&conversationId=${encodeURIComponent(p.conversationId.trim())}`;
  }
  const res = await fetch(url, {
    headers: headers(),
  });
  const resolvedConversationId = res.headers.get("X-DocViz-Resolved-Conversation-Id")?.trim() || undefined;
  const entries = await parseJson<ChatHistoryEntry[]>(res);
  return { entries, resolvedConversationId };
}
