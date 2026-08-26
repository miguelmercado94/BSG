import { randomUuid } from "../util/randomUuid";

import type {
  CellRepoRequestBody,
  CellRequestBody,
  CellResponse,
  CellRepoResponse,
  CellRepoUrlHint,
  PendingIndexBeginResponse,
  SinglePathIngestResultDto,
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
  VectorChatResponse,
  VectorClearResponse,
  VectorIngestResponse,
  WorkAreaChangeBlock,
  WorkAreaFileProposal,
  WorkAreaS3PromoteResponse,
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
 * Kept for future stream-based ingest migration.
 */
export function mergeReadyAndDoneIngestCounts(
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
  return parseJson<SecurityAuthToken>(res, "security");
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
  return parseJson<RegisterUserResponse>(res, "security");
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

type ProxyFailureKind = "docviz" | "security";

/** Si Nginx devuelve HTML de error, evita mostrar la página entera en la UI. */
function humanizeFailedFetchMessage(
  res: Response,
  body: string,
  kind: ProxyFailureKind = "docviz",
): string {
  const raw = body.trim();
  if (
    /^<\s*html/i.test(raw) ||
    /<title>\s*50[0-9]/i.test(raw) ||
    /502\s+Bad\s+Gateway/i.test(raw) ||
    /504\s+Gateway\s+Time-out/i.test(raw)
  ) {
    if (kind === "security") {
      return `El servicio de seguridad no está disponible (${res.status} desde el proxy). Suele indicar que el micro back-security no respondió; revisa el servicio y los logs.`;
    }
    return `El API no está disponible (${res.status} desde el proxy). Suele indicar que soporte-rag-mt no respondió; revisa el servicio y los logs.`;
  }
  return raw || res.statusText;
}

async function parseJson<T>(res: Response, proxyKind: ProxyFailureKind = "docviz"): Promise<T> {
  const text = await res.text();
  if (!res.ok) {
    let msg = humanizeFailedFetchMessage(res, text || res.statusText, proxyKind);
    try {
      const j = JSON.parse(text) as { error?: string; message?: string; detail?: string; title?: string };
      msg = j.detail ?? j.message ?? j.error ?? j.title ?? msg;
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
  const result: Record<string, string> = {
    "Content-Type": "application/json",
    [USER_HEADER]: uid,
    [DOCVIZ_ROLE_HEADER]: getDocVizRole(),
  };
  // Bearer token para el API Gateway
  const token = getAccessToken();
  if (token) {
    result["Authorization"] = `Bearer ${token}`;
  }
  return { ...result, ...extra };
}

/** Cabeceras sin Content-Type (p. ej. FormData con boundary). */
export function headersMultipart(): HeadersInit {
  const uid = getUserId();
  if (!uid) {
    throw new Error("Falta el identificador de usuario (DocViz).");
  }
  const result: Record<string, string> = {
    [USER_HEADER]: uid,
    [DOCVIZ_ROLE_HEADER]: getDocVizRole(),
  };
  const token = getAccessToken();
  if (token) {
    result["Authorization"] = `Bearer ${token}`;
  }
  return result;
}


// ─────────────────────────────────────────────────────────────────────────────
// Git connection
// ─────────────────────────────────────────────────────────────────────────────

function buildFolderTree(paths: string[], rootName?: string): FolderStructureDto {
  const root: FolderStructureDto = { folder: rootName || "", archivos: [], folders: [] };

  for (const path of paths) {
    const parts = path.split("/");
    let current = root;

    for (let i = 0; i < parts.length; i++) {
      const part = parts[i];
      const isFile = i === parts.length - 1;

      if (isFile) {
        if (!current.archivos.includes(part)) {
          current.archivos.push(part);
        }
      } else {
        let nextDir = current.folders.find((f) => f.folder === part);
        if (!nextDir) {
          nextDir = { folder: part, archivos: [], folders: [] };
          current.folders.push(nextDir);
        }
        current = nextDir;
      }
    }
  }

  return root;
}

export async function connectGit(body: GitConnectRequest): Promise<ConnectResponse> {
  const url = body.repositoryUrl || "";
  const repoName = parseGitRepoNameFromHttpsUrl(url) || url.split("/").filter(Boolean).pop() || "repo";
  try {
    const res = await fetch(`${apiBase()}/api/v1/repositorios?url=${encodeURIComponent(url)}`, { headers: headers() });
    if (res.ok) {
      const r = await parseJson<any>(res);
      const files = (r.filesPath && r.filesPath.length > 0) ? r.filesPath : (r.archivosS3Workarea || []);
      return {
        usuario: getUserId(),
        connected: true,
        repositoryRoot: url,
        directory: buildFolderTree(files, r.nombre || repoName),
      };
    }
  } catch (e) {
    // ignore
  }
  return {
    usuario: getUserId(),
    connected: true,
    repositoryRoot: url,
    directory: { folder: repoName, archivos: [], folders: [] },
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// Cells (Células) — mapped to soporte-rag-mt /api/v1/celulas
// ─────────────────────────────────────────────────────────────────────────────

export async function fetchCells(): Promise<CellResponse[]> {
  const res = await fetch(`${apiBase()}/api/v1/celulas`, { headers: headers() });
  const raw = await parseJson<any[]>(res);
  return raw.map((c) => ({
    id: c.codigo,
    name: c.nombre,
    description: c.descripcion ?? "",
    createdAt: c.createdAt ?? null,
    createdBy: c.createdBy ?? null,
  })) as any;
}

export async function fetchCellRepos(cellId: string): Promise<CellRepoResponse[]> {
  const res = await fetch(`${apiBase()}/api/v1/celulas/${encodeURIComponent(cellId)}`, { headers: headers() });
  const cell = await parseJson<any>(res);
  if (!cell || !cell.repositorios) return [];
  return cell.repositorios.map((r: any) => ({
    id: r.url,
    cellId: cellId,
    displayName: r.nombre,
    repositoryUrl: r.url,
    connectionMode: r.url?.startsWith("local:") ? "LOCAL" : "HTTPS_PUBLIC",
    gitUsername: null,
    hasCredential: false,
    localPath: r.url?.startsWith("local:") ? r.url.substring(6) : null,
    tagsCsv: r.tags ? r.tags.join(", ") : null,
    vectorNamespace: r.vectorNamespace || (r.url ? newVectorNamespaceFromRepoName(r.nombre) : null),
    active: true,
    createdAt: null,
    updatedAt: null,
    lastIngestAt: null,
    lastIngestFiles: r.archivosS3Workarea ? r.archivosS3Workarea.length : 0,
    lastIngestChunks: 0,
    lastIngestSkipped: null,
    linkedWithoutReindex: !!r.indexado,
    indexado: !!r.indexado,
    ramaPrincipal: r.ramaPrincipal || undefined,
    filesPath: r.filesPath || [],
    folderPath: r.folderPath || [],
  }));
}

export async function adminCreateCell(body: CellRequestBody): Promise<CellResponse> {
  const res = await fetch(`${apiBase()}/api/v1/celulas`, {
    method: "POST",
    headers: headers(),
    body: JSON.stringify({
      codigo: body.code ?? body.name,
      nombre: body.name,
      descripcion: body.description ?? "",
    }),
  });
  const c = await parseJson<any>(res);
  return {
    id: c.codigo,
    name: c.nombre,
    description: c.descripcion ?? "",
    createdAt: c.createdAt ?? null,
    createdBy: c.createdBy ?? null,
  } as any;
}

export async function adminUpdateCell(id: string, body: CellRequestBody): Promise<CellResponse> {
  const res = await fetch(`${apiBase()}/api/v1/celulas/${id}`, {
    method: "PUT",
    headers: headers(),
    body: JSON.stringify({
      codigo: id,
      nombre: body.name,
      descripcion: body.description ?? "",
    }),
  });
  const c = await parseJson<any>(res);
  return {
    id: c.codigo,
    name: c.nombre,
    description: c.descripcion ?? "",
    createdAt: c.createdAt ?? null,
    createdBy: c.createdBy ?? null,
  } as any;
}

export async function adminDeleteCell(id: string): Promise<void> {
  const res = await fetch(`${apiBase()}/api/v1/celulas/${id}`, {
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

export async function adminFetchCellDeleteImpact(cellId: string): Promise<DeleteImpactResponse> {
  // TODO: Migrate — soporte-rag-mt no tiene endpoint de delete-impact dedicado.
  void cellId;
  return { taskCount: 0 } as DeleteImpactResponse;
}

export async function adminFetchRepoDeleteImpact(cellId: string, repoId: string): Promise<DeleteImpactResponse> {
  // TODO: Migrate — soporte-rag-mt no tiene endpoint de delete-impact dedicado.
  void cellId;
  void repoId;
  return { taskCount: 0 } as DeleteImpactResponse;
}

/** Detecta la rama principal y genera hints (nombre, namespace) desde la URL del repo. */
export async function adminRepoUrlHint(params: {
  url?: string;
  localPath?: string;
  mode: GitConnectionMode;
}): Promise<CellRepoUrlHint> {
  const url = params.url?.trim() ?? "";
  if (!url || params.mode === "LOCAL") {
    // Modo local o sin URL: generar hints en el frontend
    const name = params.localPath?.split(/[/\\]/).pop() ?? "repo";
    return {
      displayName: name,
      vectorNamespace: newVectorNamespaceFromRepoName(name),
      reusedFromExisting: false,
      defaultBranch: null,
    };
  }
  // Detectar rama principal desde el backend
  const repoName = parseGitRepoNameFromHttpsUrl(url) ?? "repo";
  let defaultBranch: string | null = null;
  try {
    const res = await fetch(
      `${apiBase()}/api/v1/repositorios/rama-principal?url=${encodeURIComponent(url)}`,
      { headers: headers() },
    );
    if (res.ok) {
      const data = await res.json() as { ramaPrincipal?: string };
      defaultBranch = data.ramaPrincipal ?? null;
    }
  } catch {
    // Network error or unavailable — leave branch as null
  }
  return {
    displayName: repoName,
    vectorNamespace: newVectorNamespaceFromRepoName(repoName),
    reusedFromExisting: false,
    defaultBranch,
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// Repos (Repositorios) — mapped to soporte-rag-mt /api/v1/repositorios
// ─────────────────────────────────────────────────────────────────────────────

export async function adminCreateRepo(cellId: string, body: CellRepoRequestBody): Promise<CellRepoResponse> {
  // soporte-rag-mt: POST /api/v1/repositorios
  const tags = body.tagsCsv ? body.tagsCsv.split(",").map((t) => t.trim()).filter(Boolean) : [];
  const res = await fetch(`${apiBase()}/api/v1/repositorios`, {
    method: "POST",
    headers: headers(),
    body: JSON.stringify({
      nombre: body.displayName || parseGitRepoNameFromHttpsUrl(body.repositoryUrl) || "repo",
      url: body.repositoryUrl,
      ramaPrincipal: (body as CellRepoRequestBody & { defaultBranch?: string }).defaultBranch || "",
      descripcion: "",
      codigoCelula: cellId,
      tags,
    }),
  });
  const r = await parseJson<any>(res);
  return {
    id: r.url,
    cellId: cellId,
    displayName: r.nombre,
    repositoryUrl: r.url,
    connectionMode: r.url?.startsWith("local:") ? "LOCAL" : "HTTPS_PUBLIC",
    gitUsername: null,
    hasCredential: false,
    localPath: r.url?.startsWith("local:") ? r.url.substring(6) : null,
    tagsCsv: r.tags ? r.tags.join(", ") : null,
    vectorNamespace: r.vectorNamespace || (r.url ? newVectorNamespaceFromRepoName(r.nombre) : null),
    active: true,
    createdAt: null,
    updatedAt: null,
    lastIngestAt: null,
    lastIngestFiles: r.archivosS3Workarea ? r.archivosS3Workarea.length : 0,
    lastIngestChunks: 0,
    lastIngestSkipped: null,
    linkedWithoutReindex: !!r.indexado,
    indexado: !!r.indexado,
    filesPath: r.filesPath || [],
    folderPath: r.folderPath || [],
  };
}

/**
 * Crea repo en la célula con NDJSON de progreso (archivos, chunks) y evento final CELL_REPO_READY.
 * TODO: Migrate to frontend-side implementation (Git/S3 libraries).
 * soporte-rag-mt usa POST /api/v1/repositorios/indexar para indexar.
 */
export async function adminCreateRepoStream(
  cellId: string,
  body: CellRepoRequestBody,
  onProgress: (ev: IngestProgressEvent) => void,
  init?: { signal?: AbortSignal },
): Promise<CellRepoResponse> {
  onProgress({ phase: "START", totalFiles: 0, filesProcessed: 0, chunksIndexed: 0 });
  const r = await adminCreateRepo(cellId, body);
  if (r.linkedWithoutReindex) {
    onProgress({
      phase: "CELL_REPO_READY",
      cellRepoId: r.id,
      displayName: r.displayName,
      filesProcessed: r.lastIngestFiles ?? 0,
      chunksIndexed: r.lastIngestChunks ?? 0,
      namespace: r.vectorNamespace ?? "",
      linkedWithoutReindex: true,
    });
    return r;
  }

  try {
    const response = await fetch(`${apiBase()}/api/v1/repositorios/indexar?url=${encodeURIComponent(r.id)}`, {
      method: "POST",
      headers: headers(),
      signal: init?.signal,
    });
    
    if (response.ok && response.body) {
      const reader = response.body.getReader();
      const decoder = new TextDecoder();
      let buffer = "";
      let filesProcessed = 0;
      let totalFiles = r.filesPath?.length ?? r.lastIngestFiles ?? 0;
      
      while (true) {
        const { done, value } = await reader.read();
        if (done) break;
        
        buffer += decoder.decode(value, { stream: true });
        const lines = buffer.split("\n");
        buffer = lines.pop() || "";
        
        for (const line of lines) {
          if (!line.trim()) continue;
          try {
            const update = JSON.parse(line);
            filesProcessed++;
            onProgress({
              phase: "PROGRESS",
              totalFiles,
              filesProcessed,
              chunksIndexed: filesProcessed,
              currentFile: update.filePath,
              detail: update.mensaje || "Indexando...",
            });
          } catch (e) {
            console.error("Failed to parse progress line", e);
          }
        }
      }
    }
  } catch (err) {
    console.error("Streaming indexation failed", err);
  }

  // Fetch updated repository details from the backend to get the actual filesPath, folderPath, etc.
  let finalRepo = r;
  try {
    const res = await fetch(`${apiBase()}/api/v1/repositorios?url=${encodeURIComponent(r.id)}`, { headers: headers() });
    if (res.ok) {
      const updated = await parseJson<any>(res);
      finalRepo = {
        id: updated.url,
        cellId: cellId,
        displayName: updated.nombre,
        repositoryUrl: updated.url,
        connectionMode: updated.url?.startsWith("local:") ? "LOCAL" : "HTTPS_PUBLIC",
        gitUsername: null,
        hasCredential: false,
        localPath: updated.url?.startsWith("local:") ? updated.url.substring(6) : null,
        tagsCsv: updated.tags ? updated.tags.join(", ") : null,
        vectorNamespace: updated.vectorNamespace || (updated.url ? newVectorNamespaceFromRepoName(updated.nombre) : null),
        active: true,
        createdAt: null,
        updatedAt: null,
        lastIngestAt: null,
        lastIngestFiles: updated.archivosS3Workarea ? updated.archivosS3Workarea.length : 0,
        lastIngestChunks: 0,
        lastIngestSkipped: null,
        linkedWithoutReindex: !!updated.indexado,
        indexado: !!updated.indexado,
        filesPath: updated.filesPath || [],
        folderPath: updated.folderPath || [],
      };
    }
  } catch (err) {
    console.error("Failed to fetch updated repository details", err);
  }

  onProgress({
    phase: "CELL_REPO_READY",
    cellRepoId: finalRepo.id,
    displayName: finalRepo.displayName,
    filesProcessed: finalRepo.filesPath?.length ?? finalRepo.lastIngestFiles ?? 0,
    chunksIndexed: finalRepo.lastIngestChunks ?? 0,
    namespace: finalRepo.vectorNamespace ?? "",
    linkedWithoutReindex: finalRepo.linkedWithoutReindex ?? false,
  });
  return finalRepo;
}

/**
 * Indexa un repositorio sin célula (NDJSON).
 * TODO: Migrate to frontend-side implementation (Git/S3 libraries).
 */
export async function adminIndexRepoStream(
  body: CellRepoRequestBody,
  onProgress: (ev: IngestProgressEvent) => void,
  init?: { signal?: AbortSignal },
): Promise<CellRepoResponse> {
  onProgress({ phase: "START", totalFiles: 0, filesProcessed: 0, chunksIndexed: 0 });
  const res = await fetch(`${apiBase()}/api/v1/repositorios`, {
    method: "POST",
    headers: headers(),
    body: JSON.stringify(body),
    signal: init?.signal,
  });
  const repo = await parseJson<any>(res);
  const mapped: CellRepoResponse = {
    id: repo.url,
    cellId: null,
    displayName: repo.nombre,
    repositoryUrl: repo.url,
    connectionMode: repo.url?.startsWith("local:") ? "LOCAL" : "HTTPS_PUBLIC",
    gitUsername: null,
    hasCredential: false,
    localPath: repo.url?.startsWith("local:") ? repo.url.substring(6) : null,
    tagsCsv: repo.tags ? repo.tags.join(", ") : null,
    vectorNamespace: repo.url ? newVectorNamespaceFromRepoName(repo.nombre) : null,
    active: true,
    createdAt: null,
    updatedAt: null,
    lastIngestAt: null,
    lastIngestFiles: repo.archivosS3Workarea ? repo.archivosS3Workarea.length : 0,
    lastIngestChunks: 0,
    lastIngestSkipped: null,
    linkedWithoutReindex: true,
  };
  onProgress({
    phase: "CELL_REPO_READY",
    cellRepoId: mapped.id,
    displayName: mapped.displayName ?? "",
    filesProcessed: mapped.lastIngestFiles ?? 0,
    chunksIndexed: mapped.lastIngestChunks ?? 0,
    namespace: mapped.vectorNamespace ?? "",
    linkedWithoutReindex: mapped.linkedWithoutReindex,
  });
  return mapped;
}

export async function adminBeginPendingIndex(body: CellRepoRequestBody): Promise<PendingIndexBeginResponse> {
  // TODO: Migrate to frontend-side implementation (Git/S3 libraries).
  // soporte-rag-mt no tiene pending index flow.
  void body;
  throw new Error("Not implemented: adminBeginPendingIndex — pending migration.");
}

export async function adminListPendingIngestPaths(repoId: string): Promise<string[]> {
  // TODO: Migrate to frontend-side implementation (Git/S3 libraries).
  void repoId;
  throw new Error("Not implemented: adminListPendingIngestPaths — pending migration.");
}

export async function adminIngestOnePending(
  repoId: string,
  path: string,
): Promise<SinglePathIngestResultDto> {
  // soporte-rag-mt: POST /api/v1/repositorios/indexar-archivo
  const res = await fetch(`${apiBase()}/api/v1/repositorios/indexar-archivo`, {
    method: "POST",
    headers: headers(),
    body: JSON.stringify({ urlRepo: repoId, filePath: path }),
  });
  const r = await parseJson<any>(res);
  return {
    indexed: r.exitoso,
    skipped: !r.exitoso,
    path: r.filePath || path,
    chunksIndexed: r.exitoso ? 1 : 0,
    skipReason: !r.exitoso ? r.mensaje : null,
    errorMessage: !r.exitoso ? r.mensaje : null,
  };
}

export async function adminFinishPendingIndex(repoId: string): Promise<CellRepoResponse> {
  // TODO: Migrate to frontend-side implementation (Git/S3 libraries).
  void repoId;
  throw new Error("Not implemented: adminFinishPendingIndex — pending migration.");
}

export async function adminAbortPendingIndex(repoId: string): Promise<void> {
  // TODO: Migrate to frontend-side implementation (Git/S3 libraries).
  void repoId;
  throw new Error("Not implemented: adminAbortPendingIndex — pending migration.");
}

export async function adminAssignReposToCell(cellId: string, repoIds: string[]): Promise<CellRepoResponse[]> {
  // TODO: Migrate to frontend-side implementation (Git/S3 libraries).
  // soporte-rag-mt no tiene assign-to-cell endpoint.
  void cellId;
  void repoIds;
  throw new Error("Not implemented: adminAssignReposToCell — pending migration.");
}

export async function adminDeletePendingRepo(repoId: string): Promise<void> {
  // TODO: Migrate to frontend-side implementation (Git/S3 libraries).
  void repoId;
  throw new Error("Not implemented: adminDeletePendingRepo — pending migration.");
}

export async function adminDeleteRepo(cellId: string, repoId: string): Promise<void> {
  // soporte-rag-mt: DELETE /api/v1/celulas/{codigoCelula}/repositorios?urlRepo={repoId}
  const res = await fetch(`${apiBase()}/api/v1/celulas/${cellId}/repositorios?urlRepo=${encodeURIComponent(repoId)}`, {
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

/** Lista todas las ramas de un repositorio remoto. La primera es la principal. */
export async function fetchRepoBranches(repoUrl: string): Promise<Array<{nombre: string; commit: string}>> {
  const res = await fetch(
    `${apiBase()}/api/v1/repositorios/ramas?url=${encodeURIComponent(repoUrl)}`,
    { headers: headers() },
  );
  if (!res.ok) return [];
  return parseJson<Array<{nombre: string; commit: string}>>(res);
}

/** Actualiza un repositorio (cambio de rama, tags, reindexar si cambió rama). */
export async function updateRepo(body: {
  url: string;
  ramaPrincipal?: string;
  descripcion?: string;
  tags?: string[];
}): Promise<unknown> {
  const res = await fetch(`${apiBase()}/api/v1/repositorios`, {
    method: "PUT",
    headers: headers(),
    body: JSON.stringify(body),
  });
  return parseJson<unknown>(res);
}


// ─────────────────────────────────────────────────────────────────────────────
// Repo tree / file browsing
// TODO: Migrate to frontend-side implementation (Git/S3 libraries).
// soporte-rag-mt no expone tree/file endpoints.
// ─────────────────────────────────────────────────────────────────────────────

export async function adminFetchRepoTree(_cellId: string, repoId: string): Promise<FolderStructureDto> {
  try {
    const res = await fetch(`${apiBase()}/api/v1/repositorios?url=${encodeURIComponent(repoId)}`, { headers: headers() });
    if (res.ok) {
      const r = await parseJson<any>(res);
      const paths = (r.filesPath && r.filesPath.length > 0) ? r.filesPath : (r.archivosS3Workarea || []);
      return buildFolderTree(paths);
    }
  } catch {
    // ignore
  }
  return { folder: "", archivos: [], folders: [] };
}

export async function adminFetchRepoFile(_cellId: string, repoId: string, path: string): Promise<FileContentResponse> {
  if (repoId.includes("github.com")) {
    try {
      const cleanUrl = repoId.replace(/\.git$/, "");
      const match = cleanUrl.match(/github\.com\/([^/]+)\/([^/]+)/);
      if (match) {
        const [, owner, repo] = match;
        let branch = "main";
        try {
          const repoRes = await fetch(`${apiBase()}/api/v1/repositorios?url=${encodeURIComponent(repoId)}`, { headers: headers() });
          if (repoRes.ok) {
            const r = await repoRes.json();
            branch = r.ramaPrincipal || "main";
          }
        } catch {
          // ignore
        }
        const rawUrl = `https://raw.githubusercontent.com/${owner}/${repo}/${branch}/${path}`;
        const rawRes = await fetch(rawUrl);
        if (rawRes.ok) {
          const content = await rawRes.text();
          return { path, content, encoding: "utf-8" };
        }
      }
    } catch {
      // ignore
    }
  }
  return {
    path,
    content: `// Vista previa de ${path}\n// El contenido real del archivo se encuentra en el repositorio Git.`,
    encoding: "utf-8",
  };
}

export async function adminFetchPendingRepoTree(repoId: string): Promise<FolderStructureDto> {
  return adminFetchRepoTree("", repoId);
}

export async function adminFetchPendingRepoFile(repoId: string, path: string): Promise<FileContentResponse> {
  return adminFetchRepoFile("", repoId, path);
}

// ─────────────────────────────────────────────────────────────────────────────
// Support Markdown upload/delete/update (per cell/repo)
// TODO: Migrate to frontend-side implementation (Git/S3 libraries).
// soporte-rag-mt maneja soportes via /api/v1/soportes
// ─────────────────────────────────────────────────────────────────────────────

export async function adminUploadCellSupportMarkdown(
  cellId: string,
  repoId: string,
  file: File,
  huCode: string,
  huTitle: string,
): Promise<SupportMarkdownUploadResponse> {
  void cellId;
  const content = await file.text();
  const contenidoBase64 = btoa(unescape(encodeURIComponent(content)));
  const nombre = file.name.replace(/\.[^.]+$/, "");
  const body = {
    codigo: nombre.replace(/[^a-zA-Z0-9_-]/g, "_"),
    nombre,
    descripcion: `${huCode} - ${huTitle}`,
    urlRepo: repoId,
    nombreArchivo: file.name,
    contenidoBase64,
  };
  const res = await fetch(`${apiBase()}/api/v1/soportes`, {
    method: "POST",
    headers: headers(),
    body: JSON.stringify(body),
  });
  return parseJson<SupportMarkdownUploadResponse>(res);
}

export async function adminUploadPendingSupportMarkdown(
  repoId: string,
  file: File,
  huCode: string,
  huTitle: string,
): Promise<SupportMarkdownUploadResponse> {
  const content = await file.text();
  const contenidoBase64 = btoa(unescape(encodeURIComponent(content)));
  const nombre = file.name.replace(/\.[^.]+$/, "");
  const body = {
    codigo: nombre.replace(/[^a-zA-Z0-9_-]/g, "_"),
    nombre,
    descripcion: `${huCode} - ${huTitle}`,
    urlRepo: repoId,
    nombreArchivo: file.name,
    contenidoBase64,
  };
  const res = await fetch(`${apiBase()}/api/v1/soportes`, {
    method: "POST",
    headers: headers(),
    body: JSON.stringify(body),
  });
  return parseJson<SupportMarkdownUploadResponse>(res);
}

export async function adminDeleteCellSupportMarkdown(cellId: string, repoId: string, fileName: string): Promise<void> {
  void cellId;
  void repoId;
  const q = encodeURIComponent(fileName);
  const res = await fetch(`${apiBase()}/api/v1/soportes/${q}`, {
    method: "DELETE",
    headers: headers(),
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(text || res.statusText);
  }
}

export async function adminDeletePendingSupportMarkdown(repoId: string, fileName: string): Promise<void> {
  void repoId;
  const q = encodeURIComponent(fileName);
  const res = await fetch(`${apiBase()}/api/v1/soportes/${q}`, {
    method: "DELETE",
    headers: headers(),
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(text || res.statusText);
  }
}

export async function adminUpdateCellSupportMarkdown(
  cellId: string,
  repoId: string,
  fileName: string,
  content: string,
): Promise<SupportMarkdownUploadResponse> {
  void cellId;
  void repoId;
  const contenidoBase64 = btoa(unescape(encodeURIComponent(content)));
  const nombre = fileName.replace(/\.[^.]+$/, "");
  const body = {
    nombre,
    descripcion: "",
    contenidoBase64,
  };
  const q = encodeURIComponent(fileName.replace(/\.[^.]+$/, "").replace(/[^a-zA-Z0-9_-]/g, "_"));
  const res = await fetch(`${apiBase()}/api/v1/soportes/${q}`, {
    method: "PUT",
    headers: headers(),
    body: JSON.stringify(body),
  });
  return parseJson<SupportMarkdownUploadResponse>(res);
}

export async function adminUpdatePendingSupportMarkdown(
  repoId: string,
  fileName: string,
  content: string,
): Promise<SupportMarkdownUploadResponse> {
  void repoId;
  const contenidoBase64 = btoa(unescape(encodeURIComponent(content)));
  const nombre = fileName.replace(/\.[^.]+$/, "");
  const body = {
    nombre,
    descripcion: "",
    contenidoBase64,
  };
  const q = encodeURIComponent(fileName.replace(/\.[^.]+$/, "").replace(/[^a-zA-Z0-9_-]/g, "_"));
  const res = await fetch(`${apiBase()}/api/v1/soportes/${q}`, {
    method: "PUT",
    headers: headers(),
    body: JSON.stringify(body),
  });
  return parseJson<SupportMarkdownUploadResponse>(res);
}

// ─────────────────────────────────────────────────────────────────────────────
// Tasks (Tareas) — mapped to soporte-rag-mt /api/v1/tareas
// ─────────────────────────────────────────────────────────────────────────────

export async function createTask(body: TaskCreateRequest): Promise<TaskResponse> {
  const code = randomUuid();
  const payload = {
    codigoCelula: body.cellId,
    urlRepo: body.cellRepoId,
    codigoUsuario: getUserId(),
    codigoTarea: code,
    titulo: body.huCode,
    enunciadoPrincipal: body.enunciado,
  };
  const res = await fetch(`${apiBase()}/api/v1/tareas`, {
    method: "POST",
    headers: headers(),
    body: JSON.stringify(payload),
  });
  const t = await parseJson<any>(res);
  return {
    id: t.codigoTarea,
    userId: t.codigoUsuario,
    huCode: t.titulo,
    cellRepoId: t.urlRepo,
    enunciado: t.enunciadoPrincipal,
    status: t.estadoTarea,
    createdAt: null,
    continuedAt: null,
    chatConversationId: t.codigoTarea,
  };
}

/** Lista tareas del usuario actual. */
export async function fetchTasks(cellId?: string): Promise<TaskResponse[]> {
  const userId = getUserId();
  const url = `${apiBase()}/api/v1/tareas/usuario/${encodeURIComponent(userId)}`;
  const res = await fetch(url, { headers: headers() });
  const raw = await parseJson<any[]>(res);
  let filtered = raw;
  if (cellId) {
    filtered = raw.filter((t) => t.codigoCelula === cellId);
  }
  return filtered.map((t) => ({
    id: t.codigoTarea,
    userId: t.codigoUsuario,
    huCode: t.titulo,
    cellRepoId: t.urlRepo,
    enunciado: t.enunciadoPrincipal,
    status: t.estadoTarea,
    createdAt: null,
    continuedAt: null,
    chatConversationId: t.codigoTarea,
  }));
}

export async function getTask(id: string): Promise<TaskResponse> {
  const all = await fetchTasks();
  const found = all.find((t) => t.id === id);
  if (!found) throw new Error(`Tarea ${id} no encontrada.`);
  return found;
}

export async function continueTask(taskId: string): Promise<TaskContinueResponse> {
  const task = await getTask(taskId);
  const repoName = parseGitRepoNameFromHttpsUrl(task.cellRepoId) || "repo";
  return {
    taskId: task.id,
    huCode: task.huCode,
    cellRepoId: task.cellRepoId,
    gitConnect: {
      mode: task.cellRepoId.startsWith("local:") ? "LOCAL" : "HTTPS_PUBLIC",
      repositoryUrl: task.cellRepoId,
      localPath: task.cellRepoId.startsWith("local:") ? task.cellRepoId.substring(6) : undefined,
      vectorNamespace: newVectorNamespaceFromRepoName(repoName),
    },
    initialChatPrompt: `Hola, estoy trabajando en la tarea ${task.huCode} en el repositorio ${repoName}. ¿En qué me puedes ayudar?`,
    vectorNamespaceHint: newVectorNamespaceFromRepoName(repoName),
    cellName: task.chatConversationId || null,
    chatConversationId: task.chatConversationId || null,
  };
}

/** Cambia el estado de una tarea. */
export async function updateTaskStatus(codigoTarea: string, nuevoEstado: string): Promise<unknown> {
  const res = await fetch(`${apiBase()}/api/v1/tareas/${encodeURIComponent(codigoTarea)}/estado`, {
    method: "PATCH",
    headers: headers(),
    body: JSON.stringify({ nuevoEstado }),
  });
  return parseJson<unknown>(res);
}

/** Actualiza una tarea (titulo, enunciado). Solo en BORRADOR. */
export async function updateTask(codigoTarea: string, body: {
  titulo?: string;
  enunciadoPrincipal?: string;
  urlRepo?: string;
}): Promise<unknown> {
  const res = await fetch(`${apiBase()}/api/v1/tareas/${encodeURIComponent(codigoTarea)}`, {
    method: "PUT",
    headers: headers(),
    body: JSON.stringify(body),
  });
  return parseJson<unknown>(res);
}

/** Elimina una tarea. */
export async function deleteTask(codigoTarea: string): Promise<void> {
  const res = await fetch(`${apiBase()}/api/v1/tareas/${encodeURIComponent(codigoTarea)}`, {
    method: "DELETE",
    headers: headers(),
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(text || res.statusText);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Support (Soportes) — mapped to soporte-rag-mt /api/v1/soportes
// ─────────────────────────────────────────────────────────────────────────────

interface SoporteResponseDto {
  codigo: string;
  nombre: string;
  descripcion: string;
  urlRepo: string;
  nombreArchivo?: string;
  bucket?: string;
  keyS3?: string;
  urlDescargaS3?: string;
  urlS3?: string;
  pathsChunkVectorial?: string[];
}

export async function listSupportMarkdownObjects(cellRepoId: string): Promise<SupportMarkdownObjectDto[]> {
  // soporte-rag-mt: GET /api/v1/soportes?urlRepo={urlRepo}
  const url = `${apiBase()}/api/v1/soportes?urlRepo=${encodeURIComponent(cellRepoId)}`;
  const res = await fetch(url, { headers: headers() });
  if (res.status === 404) return [];
  const dtoList = await parseJson<SoporteResponseDto[]>(res);
  return dtoList.map(item => ({
    bucket: item.bucket ?? "",
    objectKey: item.keyS3 ?? "",
    fileName: item.codigo ?? "",
    url: item.urlS3 || item.urlDescargaS3 || "",
    displayLabel: item.nombre ?? item.descripcion ?? null
  }));
}

/** Descarga texto desde URL presignada S3 (GET /support/markdown/object eliminado). */
export async function fetchTextFromPresignedUrl(url: string, init?: { signal?: AbortSignal }): Promise<string> {
  let finalUrl = url;
  if (finalUrl.includes("localstack:4566")) {
    const match = finalUrl.match(/^https?:\/\/([^/:]+)\.localstack:4566\/(.*)$/);
    if (match) {
      const bucket = match[1];
      const keyPath = match[2];
      const cleanKeyPath = keyPath.startsWith("/") ? keyPath.substring(1) : keyPath;
      finalUrl = `/s3-proxy/${bucket}/${cleanKeyPath}`;
    } else {
      finalUrl = finalUrl.replace(/https?:\/\/[^/:]+:4566/, "/s3-proxy");
    }
  }
  const res = await fetch(finalUrl, { method: "GET", signal: init?.signal });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(text || res.statusText);
  }
  return res.text();
}

// ─────────────────────────────────────────────────────────────────────────────
// Tags — mapped to soporte-rag-mt /api/v1/tags
// ─────────────────────────────────────────────────────────────────────────────

export async function fetchTags(): Promise<TagsResponse> {
  const res = await fetch(`${apiBase()}/api/v1/tags`, { headers: headers() });
  const rawTags = await parseJson<TagDetail[]>(res);
  // Convertir array de TagDetail al formato TagsResponse que usa el frontend
  const tags = rawTags.map((t) => t.tag);
  const toolsByTag: Record<string, Array<{ id: string; title: string; url: string; hint?: string }>> = {};
  for (const t of rawTags) {
    if (t.herramientasUrls && t.herramientasUrls.length > 0) {
      toolsByTag[t.tag] = t.herramientasUrls.map((h, i) => ({
        id: `${t.tag}-${i}`,
        title: h.contextoUrl || h.urlTool,
        url: h.urlTool,
        hint: h.contextoUrl,
      }));
    }
  }
  return { tags, toolsByTag };
}

/** Tag response from the backend */
export interface TagDetail {
  tag: string;
  descripcionTag: string | null;
  habilitado: boolean;
  herramientasUrls: Array<{ urlTool: string; contextoUrl: string }>;
}

/** Lista todos los tags con sus herramientas. */
export async function fetchAllTags(): Promise<TagDetail[]> {
  const res = await fetch(`${apiBase()}/api/v1/tags`, { headers: headers() });
  return parseJson<TagDetail[]>(res);
}

/** Crea un nuevo tag. */
export async function createTag(body: {
  tag: string;
  descripcionTag?: string;
  herramientasUrls?: Array<{ urlTool: string; contextoUrl: string }>;
}): Promise<TagDetail> {
  const res = await fetch(`${apiBase()}/api/v1/tags`, {
    method: "POST",
    headers: headers(),
    body: JSON.stringify(body),
  });
  return parseJson<TagDetail>(res);
}

/** Actualiza un tag existente. */
export async function updateTag(nombreTag: string, body: {
  descripcionTag?: string;
  habilitado?: boolean;
}): Promise<unknown> {
  const res = await fetch(`${apiBase()}/api/v1/tags/${encodeURIComponent(nombreTag)}`, {
    method: "PUT",
    headers: headers(),
    body: JSON.stringify(body),
  });
  return parseJson<unknown>(res);
}

/** Elimina un tag. */
export async function deleteTag(nombreTag: string): Promise<void> {
  const res = await fetch(`${apiBase()}/api/v1/tags/${encodeURIComponent(nombreTag)}`, {
    method: "DELETE",
    headers: headers(),
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(text || res.statusText);
  }
}

/** Agrega una URL tool a un tag. */
export async function addTagTool(nombreTag: string, urlTool: string, contextoUrl: string): Promise<void> {
  const params = new URLSearchParams({ urlTool, contextoUrl });
  const res = await fetch(`${apiBase()}/api/v1/tags/${encodeURIComponent(nombreTag)}/tools?${params}`, {
    method: "POST",
    headers: headers(),
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(text || res.statusText);
  }
}

/** Elimina una URL tool de un tag. */
export async function removeTagTool(nombreTag: string, urlTool: string): Promise<void> {
  const params = new URLSearchParams({ urlTool });
  const res = await fetch(`${apiBase()}/api/v1/tags/${encodeURIComponent(nombreTag)}/tools?${params}`, {
    method: "DELETE",
    headers: headers(),
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(text || res.statusText);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Utility / naming
// ─────────────────────────────────────────────────────────────────────────────

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

export async function fetchFileContent(queryPath: string, repoUrl?: string, rama?: string): Promise<FileContentResponse> {
  if (!repoUrl) {
    throw new Error("Se requiere URL del repo para obtener el contenido del archivo.");
  }
  // Si no se especifica rama, detectar la principal
  let branch = rama;
  if (!branch) {
    try {
      const res = await fetch(
        `${apiBase()}/api/v1/repositorios/rama-principal?url=${encodeURIComponent(repoUrl)}`,
        { headers: headers() },
      );
      if (res.ok) {
        const data = await res.json() as { ramaPrincipal?: string };
        branch = data.ramaPrincipal ?? "main";
      } else {
        branch = "main";
      }
    } catch {
      branch = "main";
    }
  }
  const params = new URLSearchParams({ url: repoUrl, rama: branch, filePath: queryPath });
  const res = await fetch(`${apiBase()}/api/v1/repositorios/archivo?${params}`, {
    headers: headers(),
  });
  return parseJson<FileContentResponse>(res);
}


// ─────────────────────────────────────────────────────────────────────────────
// Support markdown (legacy user-facing upload)
// ─────────────────────────────────────────────────────────────────────────────

/** Se lanza cuando el backend no expone POST /support/markdown (p. ej. DOCVIZ_SUPPORT_ENABLED=false). */
export const SUPPORT_UPLOAD_API_UNAVAILABLE = "SUPPORT_UPLOAD_API_UNAVAILABLE";

export async function uploadSupportMarkdown(
  file: File,
  init?: { signal?: AbortSignal; urlRepo?: string },
): Promise<SupportMarkdownUploadResponse> {
  // soporte-rag-mt: POST /api/v1/soportes espera JSON con contenidoBase64
  const content = await file.text();
  const contenidoBase64 = btoa(unescape(encodeURIComponent(content)));
  const nombre = file.name.replace(/\.[^.]+$/, "");
  const body = {
    codigo: nombre.replace(/[^a-zA-Z0-9_-]/g, "_"),
    nombre,
    descripcion: "",
    urlRepo: init?.urlRepo ?? "",
    nombreArchivo: file.name,
    contenidoBase64,
  };
  const res = await fetch(`${apiBase()}/api/v1/soportes`, {
    method: "POST",
    headers: headers(),
    body: JSON.stringify(body),
    signal: init?.signal,
  });
  if (res.status === 404) {
    throw new Error(SUPPORT_UPLOAD_API_UNAVAILABLE);
  }
  return parseJson<SupportMarkdownUploadResponse>(res);
}

export async function deleteSupportMarkdown(fileName: string): Promise<void> {
  // soporte-rag-mt: DELETE /api/v1/soportes/{codigo}
  const q = encodeURIComponent(fileName);
  const res = await fetch(`${apiBase()}/api/v1/soportes/${q}`, {
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

// ─────────────────────────────────────────────────────────────────────────────
// Vector / ingest
// TODO: Migrate to frontend-side implementation (Git/S3 libraries).
// soporte-rag-mt usa /api/v1/repositorios/indexar para indexación.
// ─────────────────────────────────────────────────────────────────────────────

export async function vectorIngest(init?: { signal?: AbortSignal }): Promise<VectorIngestResponse> {
  // soporte-rag-mt: POST /api/v1/repositorios/indexar
  const res = await fetch(`${apiBase()}/api/v1/repositorios/indexar`, {
    method: "POST",
    headers: headers(),
    signal: init?.signal,
  });
  return parseJson<VectorIngestResponse>(res);
}

// ─────────────────────────────────────────────────────────────────────────────
// Work Area (S3 + borradores)
// TODO: Migrate to frontend-side implementation (Git/S3 libraries).
// soporte-rag-mt no expone work-area endpoints.
// ─────────────────────────────────────────────────────────────────────────────

export type WorkAreaRequestInit = { signal?: AbortSignal; taskHuCode?: string; cellLabel?: string };

export async function listWorkAreaS3Objects(
  kind: "borradores" | "workarea",
  init?: WorkAreaRequestInit,
): Promise<WorkAreaS3ObjectDto[]> {
  // TODO: Migrate to frontend-side implementation (Git/S3 libraries).
  void kind;
  void init;
  return [];
}

export async function fetchWorkAreaS3Artifacts(
  userId: string,
  taskHu: string,
  init?: WorkAreaRequestInit,
): Promise<WorkAreaS3ObjectDto[]> {
  void init;
  // Listar borradores de esta tarea (prefijo = codigoTarea/)
  const prefix = `${taskHu}/`;
  try {
    const borradores = await fetch(
      `${apiBase()}/api/v1/workspace/archivos?bucket=BORRADORES&prefijo=${encodeURIComponent(prefix)}`,
      { headers: headers() },
    );
    if (!borradores.ok) return [];
    const borradoresData = await borradores.json() as Array<{ objectKey: string; fileName: string; bucket: string; url: string }>;

    // También listar workarea
    const workarea = await fetch(
      `${apiBase()}/api/v1/workspace/archivos?bucket=WORKAREA&prefijo=${encodeURIComponent(prefix)}`,
      { headers: headers() },
    );
    let workareaData: Array<{ objectKey: string; fileName: string; bucket: string; url: string }> = [];
    if (workarea.ok) {
      workareaData = await workarea.json() as typeof workareaData;
    }

    return [...borradoresData, ...workareaData].map((item) => ({
      objectKey: item.objectKey,
      fileName: item.fileName,
      bucket: item.bucket,
      url: item.url,
    }));
  } catch {
    return [];
  }
}

export async function fetchWorkAreaS3ArtifactBody(
  bucket: string,
  objectKey: string,
  init?: WorkAreaRequestInit,
): Promise<string> {
  void init;
  // Generar URL presignada desde el backend y luego hacer GET
  const res = await fetch(
    `${apiBase()}/api/v1/workspace/archivos?bucket=${encodeURIComponent(bucket.toUpperCase())}&prefijo=${encodeURIComponent(objectKey)}`,
    { headers: headers() },
  );
  if (!res.ok) throw new Error("No se pudo obtener el archivo");
  const items = await res.json() as Array<{ url: string }>;
  if (!items.length) throw new Error("Archivo no encontrado en S3");
  // Fetch contenido desde la URL presignada
  const contentRes = await fetch(items[0].url);
  if (!contentRes.ok) throw new Error("No se pudo descargar el contenido del archivo");
  return contentRes.text();
}

export async function deleteWorkAreaS3Artifact(
  bucket: string,
  objectKey: string,
  init?: WorkAreaRequestInit,
): Promise<void> {
  void init;
  const res = await fetch(
    `${apiBase()}/api/v1/workspace/archivos?bucket=${encodeURIComponent(bucket.toUpperCase())}&clave=${encodeURIComponent(objectKey)}`,
    { method: "DELETE", headers: headers() },
  );
  if (!res.ok) {
    const text = await res.text();
    throw new Error(text || "Error al eliminar archivo");
  }
}

export async function saveWorkAreaS3WorkareaAndReindex(
  body: { objectKey: string; content: string },
  init?: WorkAreaRequestInit,
): Promise<VectorIngestResponse> {
  // TODO: Migrate to frontend-side implementation (Git/S3 libraries).
  void body;
  void init;
  throw new Error("Not implemented: saveWorkAreaS3WorkareaAndReindex — pending migration.");
}

export async function saveWorkAreaS3BorradorContent(
  body: { objectKey: string; content: string },
  init?: WorkAreaRequestInit,
): Promise<void> {
  // TODO: Migrate to frontend-side implementation (Git/S3 libraries).
  void body;
  void init;
  throw new Error("Not implemented: saveWorkAreaS3BorradorContent — pending migration.");
}

export async function promoteWorkAreaBorradorToWorkarea(
  body: { objectKey: string; content: string },
  init?: WorkAreaRequestInit,
): Promise<WorkAreaS3PromoteResponse> {
  // TODO: Migrate to frontend-side implementation (Git/S3 libraries).
  void body;
  void init;
  throw new Error("Not implemented: promoteWorkAreaBorradorToWorkarea — pending migration.");
}

export async function restoreWorkAreaFromS3(init?: WorkAreaRequestInit): Promise<TaskArtifactRestoreResponse> {
  // TODO: Migrate to frontend-side implementation (Git/S3 libraries).
  void init;
  throw new Error("Not implemented: restoreWorkAreaFromS3 — pending migration.");
}

export async function ingestWorkAreaFile(
  body: { fileName: string; content: string },
  init?: WorkAreaRequestInit,
): Promise<VectorIngestResponse> {
  // TODO: Migrate to frontend-side implementation (Git/S3 libraries).
  void body;
  void init;
  throw new Error("Not implemented: ingestWorkAreaFile — pending migration.");
}

export async function applyWorkAreaReview(
  body: {
    sourcePath: string;
    draftVersion: number;
    changeBlocks?: WorkAreaChangeBlock[];
    accepted?: boolean[];
    finalContent?: string;
  },
  init?: WorkAreaRequestInit,
): Promise<{ acceptedRelativePath: string }> {
  // TODO: Migrate to frontend-side implementation (Git/S3 libraries).
  void body;
  void init;
  throw new Error("Not implemented: applyWorkAreaReview — pending migration.");
}

export async function applyWorkAreaFinal(
  body: { sourcePath: string; draftVersion: number; finalContent: string },
  init?: WorkAreaRequestInit,
): Promise<{ acceptedRelativePath: string }> {
  // TODO: Migrate to frontend-side implementation (Git/S3 libraries).
  void body;
  void init;
  throw new Error("Not implemented: applyWorkAreaFinal — pending migration.");
}

export async function acceptWorkAreaDraft(
  draftRelativePath: string,
  init?: WorkAreaRequestInit,
): Promise<{ acceptedRelativePath: string }> {
  // TODO: Migrate to frontend-side implementation (Git/S3 libraries).
  void draftRelativePath;
  void init;
  throw new Error("Not implemented: acceptWorkAreaDraft — pending migration.");
}

export async function finalizeWorkAreaDraft(
  body: { draftRelativePath: string; finalContent: string },
  init?: WorkAreaRequestInit,
): Promise<{ acceptedRelativePath: string }> {
  // TODO: Migrate to frontend-side implementation (Git/S3 libraries).
  void body;
  void init;
  throw new Error("Not implemented: finalizeWorkAreaDraft — pending migration.");
}

export async function acceptAllWorkAreaDrafts(
  draftRelativePaths: string[],
  init?: WorkAreaRequestInit,
): Promise<{ acceptedRelativePaths: string[] }> {
  // TODO: Migrate to frontend-side implementation (Git/S3 libraries).
  void draftRelativePaths;
  void init;
  throw new Error("Not implemented: acceptAllWorkAreaDrafts — pending migration.");
}

export async function fetchWorkAreaDraftContent(
  draftRelativePath: string,
  init?: WorkAreaRequestInit,
): Promise<{ content: string }> {
  // TODO: Migrate to frontend-side implementation (Git/S3 libraries).
  void draftRelativePath;
  void init;
  throw new Error("Not implemented: fetchWorkAreaDraftContent — pending migration.");
}

export async function deleteWorkAreaDraft(path: string, init?: WorkAreaRequestInit): Promise<void> {
  // TODO: Migrate to frontend-side implementation (Git/S3 libraries).
  void path;
  void init;
  throw new Error("Not implemented: deleteWorkAreaDraft — pending migration.");
}

export async function indexWorkAreaFileFromPath(
  relativePath: string,
  init?: WorkAreaRequestInit,
): Promise<VectorIngestResponse> {
  // TODO: Migrate to frontend-side implementation (Git/S3 libraries).
  void relativePath;
  void init;
  throw new Error("Not implemented: indexWorkAreaFileFromPath — pending migration.");
}

export async function vectorClearIndex(): Promise<VectorClearResponse> {
  // TODO: Migrate to frontend-side implementation (Git/S3 libraries).
  throw new Error("Not implemented: vectorClearIndex — pending migration.");
}

/**
 * Ingesta con streaming NDJSON.
 * TODO: Migrate to frontend-side implementation (Git/S3 libraries).
 * soporte-rag-mt no expone streaming ingest.
 */
export async function vectorIngestStream(
  onProgress: (ev: IngestProgressEvent) => void,
  init?: { signal?: AbortSignal },
): Promise<VectorIngestResponse> {
  // Fallback: usar ingesta síncrona
  onProgress({ phase: "START", totalFiles: 0 });
  const r = await vectorIngest(init);
  onProgress({
    phase: "DONE",
    filesProcessed: r.filesProcessed,
    chunksIndexed: r.chunksIndexed,
    namespace: r.namespace,
    skipped: r.skipped,
  });
  return r;
}


// ─────────────────────────────────────────────────────────────────────────────
// Session / logout
// ─────────────────────────────────────────────────────────────────────────────

export async function logoutSession(): Promise<void> {
  try {
    await logoutSecurity();
  } catch {
    /* revoke best-effort; la sesión local se borra igual */
  }
  clearAuthSession();
}

// ─────────────────────────────────────────────────────────────────────────────
// Chat — mapped to soporte-rag-mt /api/v1/tareas/{codigoTarea}/chat
// ─────────────────────────────────────────────────────────────────────────────

export async function vectorChat(question: string): Promise<VectorChatResponse> {
  // TODO: vectorChat requiere un taskId; por ahora lanza error si no se usa streamVectorChat.
  void question;
  throw new Error("Not implemented: vectorChat sin taskId — usar streamVectorChat con options.taskId.");
}

const REST_RAG_DELTA_CHUNK = 480;

/**
 * Chat RAG vía POST /api/v1/tareas/{codigoTarea}/chat.
 * El historial se alinea con HU / conversationId / tarea / célula.
 * Streaming real via SSE (text/event-stream): el backend emite tokens progresivamente.
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
  options?: { taskHuCode?: string; conversationId?: string; taskId?: string; cellName?: string },
): Promise<void> {
  const uid = getUserId();
  if (!uid) {
    return Promise.reject(new Error("Falta el identificador de usuario (DocViz)."));
  }
  if (!options?.taskId) {
    return Promise.reject(new Error("Se requiere taskId para el chat con soporte-rag-mt."));
  }

  const trimmedQuestion = question?.trim() ?? "";
  if (!trimmedQuestion) {
    return Promise.reject(new Error("El mensaje no puede estar vacío."));
  }

  handlers.onStart([]);

  // SSE streaming via POST /chat/stream (text/event-stream)
  const res = await fetch(`${apiBase()}/api/v1/tareas/${options.taskId}/chat/stream`, {
    method: "POST",
    headers: headers(),
    body: JSON.stringify({ mensaje: trimmedQuestion }),
  });

  if (!res.ok) {
    const text = await res.text();
    let msg = text || res.statusText;
    try {
      const j = JSON.parse(text) as { detail?: string; message?: string; error?: string };
      msg = j.detail ?? j.message ?? j.error ?? msg;
    } catch { /* ignore */ }
    throw new Error(msg);
  }

  if (!res.body) {
    throw new Error("El servidor no devolvió un stream.");
  }

  const reader = res.body.getReader();
  const decoder = new TextDecoder();
  let buffer = "";

  while (true) {
    const { done, value } = await reader.read();
    if (done) break;

    buffer += decoder.decode(value, { stream: true });

    // SSE format: "data:token\n\n" — parse individual data lines
    const lines = buffer.split("\n");
    buffer = lines.pop() || ""; // keep incomplete line in buffer

    for (const line of lines) {
      if (line.startsWith("data:")) {
        const token = line.slice(5); // strip "data:" prefix
        if (token.trim()) {
          handlers.onDelta(token);
        }
      }
    }
  }

  // Process any remaining buffer
  if (buffer.startsWith("data:")) {
    const token = buffer.slice(5);
    if (token.trim()) {
      handlers.onDelta(token);
    }
  }
}

export type FetchChatHistoryParams = {
  conversationId?: string;
  /** Con huCode: el servidor devuelve el hilo con menor N (principal). */
  taskId?: string;
  huCode?: string;
  /** Alineado con Firestore {@code usuario_celula_hu_taskId_N}. */
  cellName?: string;
};

/** Historial del chat — recupera el historial de chat de la tarea desde soporte-rag-mt. */
export async function fetchChatHistory(
  limit = 40,
  params?: string | FetchChatHistoryParams,
): Promise<{ entries: ChatHistoryEntry[]; resolvedConversationId?: string }> {
  void limit;
  if (typeof params === "object" && params?.taskId) {
    try {
      const res = await fetch(`${apiBase()}/api/v1/tareas/${params.taskId}`, { headers: headers() });
      if (res.ok) {
        const task = await parseJson<any>(res);
        const entries: ChatHistoryEntry[] = (task.msgChat || []).map((msg: any, index: number) => ({
          id: `${params.taskId}-${index}`,
          question: msg.textoEntrada,
          answer: msg.textoRespuesta,
          sources: [],
          repoLabel: "",
          createdAt: msg.horaRespuesta || null,
        }));
        return { entries, resolvedConversationId: params.taskId };
      }
    } catch (e) {
      console.error("Error fetching chat history from backend", e);
    }
  }
  return { entries: [], resolvedConversationId: undefined };
}

// ─────────────────────────────────────────────────────────────────────────────
// Health check — mapped to soporte-rag-mt /api/v1/infraestructura/salud
// ─────────────────────────────────────────────────────────────────────────────

export async function healthCheck(): Promise<Record<string, unknown>> {
  const res = await fetch(`${apiBase()}/api/v1/infraestructura/salud`, { headers: headers() });
  return parseJson<Record<string, unknown>>(res);
}
