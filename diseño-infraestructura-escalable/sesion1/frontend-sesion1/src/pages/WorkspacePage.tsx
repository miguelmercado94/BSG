import { FormEvent, KeyboardEvent, useCallback, useEffect, useMemo, useRef, useState } from "react";
import type { StoredTaskContext } from "../lib/docvizTaskContextStorage";
import { loadWorkspaceTaskContext, saveWorkspaceTaskContext } from "../lib/docvizTaskContextStorage";
import { loadWorkAreaIndexed, saveWorkAreaIndexed } from "../lib/workAreaIndexedStorage";

import { Link, useLocation, useNavigate } from "react-router-dom";

import {
  SUPPORT_UPLOAD_API_UNAVAILABLE,
  connectGit,
  continueTask,
  deleteSupportMarkdown,
  fetchChatHistory,
  fetchFileContent,
  fetchTextFromPresignedUrl,
  getDocVizRole,
  getUserId,
  isSupportRole,
  listSupportMarkdownObjects,
  logoutSession,
  ROLE_ADMINISTRATOR,
  ROLE_SUPPORT,
  acceptAllWorkAreaDrafts,
  acceptWorkAreaDraft,
  applyWorkAreaFinal,
  deleteWorkAreaDraft,
  deleteWorkAreaS3Artifact,
  fetchWorkAreaDraftContent,
  finalizeWorkAreaDraft,
  indexWorkAreaFileFromPath,
  fetchWorkAreaS3ArtifactBody,
  fetchWorkAreaS3Artifacts,
  saveWorkAreaS3BorradorContent,
  saveWorkAreaS3WorkareaAndReindex,
  restoreWorkAreaFromS3,
  streamVectorChat,
  uploadSupportMarkdown,
  vectorIngestStream,
} from "../api/client";

import type {
  ChatHistoryEntry,
  ConnectResponse,
  FolderStructureDto,
  SupportDocument,
  SupportUploadUiState,
  RestoredWorkAreaProposal,
  VectorIngestResponse,
  WorkAreaDiffLineKind,
  WorkAreaFileProposal,
  WorkAreaS3ObjectDto,
} from "../types";

import { FilePreviewWithLineNumbers } from "../components/FilePreviewWithLineNumbers";
import { ChatMarkdown } from "../components/ChatMarkdown";
import { ConflictInlineCodeViewer, type ConflictInlineCodeViewerHandle } from "../components/ConflictInlineCodeViewer";
import { FolderTree } from "../components/FolderTree";
import { SupportPanel } from "../components/SupportPanel";
import { extractRevisedFromMergeMarkers } from "../components/MergeConflictViewer";
import { WorkAreaConflictViewer } from "../components/WorkAreaConflictViewer";
import { WorkAreaIconDownload, WorkAreaIconTrash, WorkAreaPanel } from "../components/WorkAreaPanel";
import { useSupportDocuments } from "../hooks/useSupportDocuments";
import { useWorkspaceColumnWidths, WORKSPACE_RESIZE_HANDLE_PX } from "../hooks/useWorkspaceColumnWidths";
import { clearGitConnectRequest, loadGitConnectRequest } from "../lib/docvizGitSession";
import { workAreaProposalFallbackPayloadText } from "../lib/workAreaProposalRaw";
import { getDocvizFileMentionFromDataTransfer } from "../lib/docvizDrag";
import { resolveChatConversationId } from "../lib/chatConversationId";
import { mergeFirestoreHistoryWithLocalStream } from "../lib/chatHistoryMerge";
import { splitRagChatQuestion } from "../lib/ragChatDisplay";
import { formatChatAnswerForDisplay } from "../lib/workAreaDisplay";
import { buildResolvedDocvizMerge, hasDocvizMergeMarkers } from "../lib/docvizConflictMarkers";
import { hasGitConflictMarkers } from "../lib/parseGitConflictMarkers";

function workAreaProposalAfterAccept(p: WorkAreaFileProposal, acceptedRelativePath: string): WorkAreaFileProposal {
  const fn = acceptedRelativePath.includes("/")
    ? acceptedRelativePath.slice(acceptedRelativePath.lastIndexOf("/") + 1)
    : acceptedRelativePath;
  const dot = fn.lastIndexOf(".");
  return {
    ...p,
    acceptedRelativePath,
    draftRelativePath: undefined,
    content: "",
    diffLines: undefined,
    changeBlocks: undefined,
    vectorIndexed: undefined,
    lastIndexedChunks: undefined,
    fileName: fn,
    extension: dot > 0 ? fn.slice(dot + 1) : "",
  };
}

function normalizeWorkAreaProposals(incoming: WorkAreaFileProposal[]): WorkAreaFileProposal[] {
  return incoming.map((p) => ({
    ...p,
    diffLines: p.diffLines?.map((d) => {
      const k = String(d.kind ?? "").toLowerCase();
      const kind: WorkAreaDiffLineKind =
        k === "added" || k === "removed" || k === "context" ? k : "context";
      return { kind, text: d.text ?? "" };
    }),
  }));
}

function mapRestoredProposals(rows: RestoredWorkAreaProposal[]): WorkAreaFileProposal[] {
  return rows.map((r) => ({
    id: r.id,
    fileName: r.fileName,
    extension: r.extension,
    content: r.content ?? "",
    draftRelativePath: r.draftRelativePath ?? undefined,
    acceptedRelativePath: r.acceptedRelativePath ?? undefined,
  }));
}

/**
 * Clave lógica para borradores versionados en S3 (p. ej. `docker-compose_v1.yml.txt` y `_v2_` → mismo `docker-compose.yml`).
 * Si no encaja el patrón, cada objeto S3 sigue siendo una fila distinta.
 */
function logicalDraftKeyFromS3DraftFileName(fileName: string): string | null {
  const s = fileName.replace(/\\/g, "/");
  if (!/_v\d+/i.test(s)) return null;
  let t = /\.txt$/i.test(s) ? s.slice(0, -4) : s;
  const replaced = t.replace(/_v\d+(?=\.[^./]+$)/i, "");
  return replaced === t ? null : replaced;
}

function draftVersionFromS3DraftFileName(fileName: string): number {
  const m = fileName.match(/_v(\d+)/i);
  return m ? parseInt(m[1], 10) : 0;
}

/** Deja una sola fila por archivo lógico: gana la mayor `_vN_` y, en empate, la clave S3 lexicográficamente mayor. */
function dedupeWorkAreaS3Artifacts(items: WorkAreaS3ObjectDto[]): WorkAreaS3ObjectDto[] {
  const best = new Map<string, WorkAreaS3ObjectDto>();
  const verOf = new Map<string, number>();
  for (const item of items) {
    const logical = logicalDraftKeyFromS3DraftFileName(item.fileName);
    const key =
      logical != null ? `${item.bucket}:${logical}` : `__unique__:${item.bucket}:${item.objectKey}`;
    const ver = draftVersionFromS3DraftFileName(item.fileName);
    const cur = best.get(key);
    if (!cur || ver > (verOf.get(key) ?? -1) || (ver === (verOf.get(key) ?? -1) && item.objectKey > cur.objectKey)) {
      best.set(key, item);
      verOf.set(key, ver);
    }
  }
  const seen = new Set<string>();
  const out: WorkAreaS3ObjectDto[] = [];
  for (const item of items) {
    const logical = logicalDraftKeyFromS3DraftFileName(item.fileName);
    const key =
      logical != null ? `${item.bucket}:${logical}` : `__unique__:${item.bucket}:${item.objectKey}`;
    if (seen.has(key)) continue;
    seen.add(key);
    const chosen = best.get(key);
    if (chosen) out.push(chosen);
  }
  return out;
}

/**
 * Quita el objeto `*_vN.ext` si en el mismo bucket existe el borrador DocViz `*_vN.ext.txt` (evita dos chips y URLs
 * obsoletas para el mismo borrador).
 */
function dropBareS3DraftIfTxtTwinExists(items: WorkAreaS3ObjectDto[]): WorkAreaS3ObjectDto[] {
  const combo = new Set(items.map((i) => `${i.bucket}\0${i.fileName}`));
  return items.filter((i) => {
    if (i.fileName.toLowerCase().endsWith(".txt")) return true;
    if (combo.has(`${i.bucket}\0${i.fileName}.txt`)) return false;
    return true;
  });
}

/** Respuesta GET /s3-artifacts: solo metadatos S3 + URL; la vista carga el texto con la URL presignada. */
function mapUnifiedS3ArtifactsToProposals(items: WorkAreaS3ObjectDto[]): WorkAreaFileProposal[] {
  return items.map((item) => {
    const fn = item.fileName.includes("/")
      ? item.fileName.slice(item.fileName.lastIndexOf("/") + 1)
      : item.fileName;
    const dot = fn.lastIndexOf(".");
    const safeKey = `${item.bucket}-${item.objectKey}`.replace(/[^a-zA-Z0-9_-]/g, "_");
    return {
      id: `s3-artifact-${safeKey}`,
      fileName: fn,
      extension: dot > 0 ? fn.slice(dot + 1) : "",
      content: "",
      s3PresignedUrl: item.url,
      s3Bucket: item.bucket,
      s3ObjectKey: item.objectKey,
      artifactViewOnly: true,
    };
  });
}

/**
 * La columna «Archivos nuevos» solo debe listar entradas con objeto real en S3 (presign) o restauradas desde S3;
 * no propuestas solo en memoria devueltas por el último turno del chat (sin objeto en S3).
 */
function isWorkareaS3Artifact(p: WorkAreaFileProposal): boolean {
  return Boolean(
    p.artifactViewOnly && p.s3Bucket && /workarea/i.test(p.s3Bucket) && p.s3ObjectKey?.trim(),
  );
}

/** Borrador versionado solo en bucket borradores (lista GET /s3-artifacts). */
function isS3BorradorArtifact(p: WorkAreaFileProposal): boolean {
  return Boolean(
    p.artifactViewOnly && p.s3Bucket && /borrador/i.test(p.s3Bucket) && p.s3ObjectKey?.trim(),
  );
}

/** Vista solo-S3 editable (texto UTF-8 en borradores o workarea). */
function isEditableS3Artifact(p: WorkAreaFileProposal): boolean {
  return isWorkareaS3Artifact(p) || isS3BorradorArtifact(p);
}

function workAreaProposalVisibleInWorkAreaPanel(p: WorkAreaFileProposal): boolean {
  if (p.s3PresignedUrl?.trim()) return true;
  if (p.s3Bucket?.trim() && p.s3ObjectKey?.trim()) return true;
  if (p.id.startsWith("s3-restore-")) return true;
  if (p.vectorIndexed) return true;
  return false;
}

function workAreaPanelFileBaseName(p: WorkAreaFileProposal): string {
  const s = p.fileName.replace(/\\/g, "/");
  return (s.includes("/") ? s.slice(s.lastIndexOf("/") + 1) : s).toLowerCase();
}

/**
 * Mismo nombre que una fila del GET /s3-artifacts (bucket+clave) pero fila heredada del WS solo con URL:
 * se oculta el duplicado para un solo chip con descarga/eliminación.
 */
function dedupeWorkAreaPanelProposals(list: WorkAreaFileProposal[]): WorkAreaFileProposal[] {
  const hasFullS3ByBase = new Set<string>();
  for (const p of list) {
    if (p.s3Bucket?.trim() && p.s3ObjectKey?.trim()) {
      hasFullS3ByBase.add(workAreaPanelFileBaseName(p));
    }
  }
  return list.filter((p) => {
    if (p.s3Bucket?.trim() && p.s3ObjectKey?.trim()) return true;
    const base = workAreaPanelFileBaseName(p);
    if (hasFullS3ByBase.has(base)) return false;
    return true;
  });
}

function workspaceRoleLabel(): string {
  const r = getDocVizRole();
  if (r === ROLE_SUPPORT) return "Soporte";
  if (r === ROLE_ADMINISTRATOR) return "Administrador";
  return r || "—";
}

type LocationState = {
  connect?: ConnectResponse;
  /** Ingesta ya hecha en la pantalla de conexión */
  initialIngest?: VectorIngestResponse;
  /** Primer mensaje RAG al continuar una tarea de soporte */
  initialChatPrompt?: string;
  /** Listar .md de soporte del repo de celda (solo lectura para soporte) */
  taskCellRepoId?: number;
  /** Contexto de tarea (soporte): enunciado + vuelta a lista de célula/tareas */
  taskContext?: {
    taskId?: number;
    /** Desde {@code docviz_task.chat_conversation_id} (PostgreSQL). */
    chatConversationId?: string | null;
    huCode: string;
    enunciado: string;
    cellLabel?: string;
    returnPath: string;
    /** Entrada con «Continuar en workspace»: no reenviar el primer prompt salvo historial vacío. */
    resumeWorkspaceChat?: boolean;
  };
};

type FileViewSource = "repo" | "support" | "workarea";



const FILE_PREVIEW_LRU_MAX = 5;



function lruMapGet(map: Map<string, string>, key: string): string | undefined {

  const v = map.get(key);

  if (v === undefined) return undefined;

  map.delete(key);

  map.set(key, v);

  return v;

}



function lruMapPut(map: Map<string, string>, key: string, value: string, max: number) {

  map.delete(key);

  map.set(key, value);

  while (map.size > max) {

    const first = map.keys().next().value as string | undefined;

    if (first === undefined) break;

    map.delete(first);

  }

}



/** Último segmento de una ruta relativa (nombre de archivo o carpeta). */

function basenameRel(rel: string): string {

  const normalized = rel.replace(/\\/g, "/").replace(/\/+$/, "");

  const i = normalized.lastIndexOf("/");

  return i >= 0 ? normalized.slice(i + 1) : normalized;

}

function isRepoSessionLostError(msg: string | null): boolean {
  if (!msg) return false;
  return (
    /not connected to a repository/i.test(msg) ||
    /no conectado al repositorio/i.test(msg)
  );
}

export function WorkspacePage() {

  const navigate = useNavigate();

  const location = useLocation();

  const state = location.state as LocationState | undefined;

  const [connect, setConnect] = useState<ConnectResponse | null>(state?.connect ?? null);

  /** Tras F5 se pierde location.state; rehidrata sesión Git con sessionStorage + POST /connect/git */
  const [restorePhase, setRestorePhase] = useState<"idle" | "trying">(() => {
    if (state?.connect) return "idle";
    return loadGitConnectRequest() ? "trying" : "idle";
  });

  const [reconnectLoading, setReconnectLoading] = useState(false);

  const taskCellRepoId = state?.taskCellRepoId;
  const initialChatPromptFromTask = state?.initialChatPrompt;
  const taskContextFromRoute = state?.taskContext;

  /** Si entras a /app sin state (p. ej. nuevo login), recupera HU/tarea para historial Firestore y cabeceras S3. */
  const [taskContextFromStorage, setTaskContextFromStorage] = useState<StoredTaskContext | null>(null);

  useEffect(() => {
    if (taskContextFromRoute) {
      const u = getUserId();
      if (u?.trim()) {
        saveWorkspaceTaskContext(u, taskContextFromRoute);
      }
      setTaskContextFromStorage(null);
      return;
    }
    const u = connect?.usuario ?? getUserId();
    if (!u?.trim()) {
      setTaskContextFromStorage(null);
      return;
    }
    setTaskContextFromStorage(loadWorkspaceTaskContext(u));
  }, [taskContextFromRoute, connect?.usuario]);

  const taskContext = taskContextFromRoute ?? taskContextFromStorage ?? undefined;

  const resumeWorkspaceChat = taskContext?.resumeWorkspaceChat === true;

  /**
   * Cabeceras REST para S3 borrador/workarea (HU + célula).
   * Incluye HU desde sessionStorage si el estado de ruta aún no lo tiene (p. ej. tras F5) — debe coincidir con
   * finalize/index o el backend usará `default` y no borrará el objeto en `borrador/` del HU real.
   */
  const workAreaTaskHeaders = useMemo(() => {
    const o: { taskHuCode?: string; cellLabel?: string } = {};
    const uid = connect?.usuario?.trim() || getUserId()?.trim();
    const stored = uid ? loadWorkspaceTaskContext(uid) : null;
    const hu = taskContext?.huCode?.trim() || stored?.huCode?.trim();
    const cell = taskContext?.cellLabel?.trim() || stored?.cellLabel?.trim();
    if (hu) o.taskHuCode = hu;
    if (cell) o.cellLabel = cell;
    return Object.keys(o).length > 0 ? o : undefined;
  }, [taskContext?.huCode, taskContext?.cellLabel, connect?.usuario]);

  /** Alineado con backend: `{vectorNamespace}/workarea/{userId}/{taskCode}/` (docviz.workspace-s3). */
  const workAreaPersistenceHint = useMemo(() => {
    const uid = connect?.usuario?.trim() || getUserId()?.trim();
    const stored = uid ? loadWorkspaceTaskContext(uid) : null;
    const hu = taskContext?.huCode?.trim() || stored?.huCode?.trim();
    if (!hu || !uid) return null;
    return `S3 por tarea (tras el prefijo del namespace del repo): borrador/${uid}/${hu}/ mientras el .txt está activo; workarea/${uid}/${hu}/ cuando está aceptado (y se re-sincroniza al indexar en RAG). Al reabrir con esta HU se restauran al clon.`;
  }, [taskContext?.huCode, connect?.usuario]);

  /** Si viene de ConnectRepoPage tras indexar, no repetir ingesta al abrir el workspace */
  const initialIngestFromConnect = useRef(state?.initialIngest ?? undefined);

  const [serverSupportDocs, setServerSupportDocs] = useState<SupportDocument[]>([]);



  const [selectedPath, setSelectedPath] = useState<string | null>(null);

  const [fileContent, setFileContent] = useState<string | null>(null);

  const [fileErr, setFileErr] = useState<string | null>(null);



  const [ingestComplete, setIngestComplete] = useState(!!state?.initialIngest);

  const [ingestResult, setIngestResult] = useState<{

    filesProcessed: number;

    chunksIndexed: number;

    namespace: string;

    skipped: string[];

  } | null>(() =>
    state?.initialIngest
      ? {
          filesProcessed: state.initialIngest.filesProcessed,
          chunksIndexed: state.initialIngest.chunksIndexed,
          namespace: state.initialIngest.namespace,
          skipped: state.initialIngest.skipped ?? [],
        }
      : null,
  );

  const [ingestErr, setIngestErr] = useState<string | null>(null);

  const [ingestLoading, setIngestLoading] = useState(false);

  const [ingestProgress, setIngestProgress] = useState<{

    totalFiles: number;

    filesProcessed: number;

    chunksIndexed: number;

    currentFile: string | null;

    detail: string | null;

    /** stream = NDJSON con progreso por archivo; sync reservado si en el futuro se usa ingesta sin stream */
    mode: "sync" | "stream";

  } | null>(null);



  const [question, setQuestion] = useState("");

  const onQuestionDragOver = useCallback((e: React.DragEvent<HTMLTextAreaElement>) => {
    if (!ingestComplete) return;
    e.preventDefault();
    e.dataTransfer.dropEffect = "copy";
  }, [ingestComplete]);

  const [workAreaProposals, setWorkAreaProposals] = useState<WorkAreaFileProposal[]>([]);
  const [workAreaSelectedId, setWorkAreaSelectedId] = useState<string | null>(null);
  const [workAreaNotice, setWorkAreaNotice] = useState<string | null>(null);
  const [workAreaKeepLoadingId, setWorkAreaKeepLoadingId] = useState<string | null>(null);
  const [workAreaErr, setWorkAreaErr] = useState<string | null>(null);
  /** Si la propuesta no incluyó `content`, GET /vector/work-area/draft rellena la vista previa. */
  const [workAreaPreviewLoadingId, setWorkAreaPreviewLoadingId] = useState<string | null>(null);
  const workAreaDraftFetchKeysRef = useRef<Set<string>>(new Set());
  const workAreaConflictViewerRef = useRef<ConflictInlineCodeViewerHandle>(null);
  /** Texto ya resuelto para borradores con marcadores DocViz (sin `<<<<<<<`). */
  const [workAreaResolvedDraft, setWorkAreaResolvedDraft] = useState<string | null>(null);
  /** Edición in-place de objetos ya en bucket workarea o borradores (S3). */
  const [workAreaS3Editing, setWorkAreaS3Editing] = useState(false);
  const [workAreaS3EditDraft, setWorkAreaS3EditDraft] = useState("");
  /** Borrador .txt en el clon (no solo-S3): editor tras resolver conflictos o revisar texto antes de finalizar. */
  const [workAreaCloneDraftEditing, setWorkAreaCloneDraftEditing] = useState(false);
  const [workAreaCloneDraftBuffer, setWorkAreaCloneDraftBuffer] = useState("");
  const onWorkAreaDocvizResolved = useCallback((s: string) => {
    setWorkAreaResolvedDraft(s);
  }, []);
  /** Evita repetir POST /vector/work-area/restore-s3 para la misma tarea y mismo clon. */
  const taskArtifactRestoreKeyRef = useRef<string | null>(null);
  /** Para detectar propuestas nuevas y enfocar la última sin depender de un clic manual. */
  const prevWorkAreaProposalCountRef = useRef(0);

  const mergeWorkAreaProposals = useCallback((incoming: WorkAreaFileProposal[]) => {
    if (incoming.length === 0) return;
    const normalized = normalizeWorkAreaProposals(incoming);
    setWorkAreaProposals((prev) => {
      let changed = false;
      const next = [...prev];
      for (const p of normalized) {
        if (p.draftRelativePath) {
          const idx = next.findIndex((x) => x.draftRelativePath === p.draftRelativePath);
          if (idx >= 0) {
            if (p.s3PresignedUrl && !next[idx].s3PresignedUrl) {
              next[idx] = { ...next[idx], s3PresignedUrl: p.s3PresignedUrl };
              changed = true;
            }
            continue;
          }
        }
        if (p.acceptedRelativePath) {
          const normAcc = p.acceptedRelativePath.replace(/\\/g, "/");
          const idx = next.findIndex(
            (x) =>
              x.acceptedRelativePath != null &&
              x.acceptedRelativePath.replace(/\\/g, "/") === normAcc,
          );
          if (idx >= 0) {
            if (p.s3PresignedUrl && !next[idx].s3PresignedUrl) {
              next[idx] = { ...next[idx], s3PresignedUrl: p.s3PresignedUrl };
              changed = true;
            }
            const pContent = p.content?.trim() ?? "";
            const oldContent = next[idx].content?.trim() ?? "";
            if (pContent.length > 0 && oldContent.length === 0) {
              next[idx] = { ...next[idx], content: p.content };
              changed = true;
            }
            continue;
          }
        }
        if (!next.some((x) => x.id === p.id)) {
          next.push(p);
          changed = true;
        }
      }
      return changed ? next : prev;
    });
  }, []);

  const refreshWorkAreaS3List = useCallback(async () => {
    const hu = taskContext?.huCode?.trim();
    const uid = connect?.usuario?.trim() || getUserId()?.trim();
    if (!hu || !uid) return;
    const cell = taskContext?.cellLabel?.trim();
    try {
      const items = await fetchWorkAreaS3Artifacts(uid, hu, { taskHuCode: hu, cellLabel: cell });
      workAreaDraftFetchKeysRef.current.clear();
      const mapped = mapUnifiedS3ArtifactsToProposals(
        dropBareS3DraftIfTxtTwinExists(dedupeWorkAreaS3Artifacts(items)),
      );
      setWorkAreaProposals((prev) => {
        const kept = prev.filter(
          (p) =>
            p.artifactViewOnly !== true &&
            !String(p.id).startsWith("s3-list-") &&
            !String(p.id).startsWith("s3-wa-"),
        );
        return [...kept, ...mapped];
      });
    } catch {
      /* S3 deshabilitado o red */
    }
  }, [taskContext?.huCode, taskContext?.cellLabel, connect?.usuario]);

  /** Tras una respuesta de chat con propuestas: no fusionar JSON del WS; el objeto está en S3 tras el backend. */
  const onWorkAreaChatProposals = useCallback(() => {
    void refreshWorkAreaS3List();
    window.setTimeout(() => void refreshWorkAreaS3List(), 1200);
  }, [refreshWorkAreaS3List]);

  const workAreaPanelProposals = useMemo(
    () =>
      dedupeWorkAreaPanelProposals(workAreaProposals.filter(workAreaProposalVisibleInWorkAreaPanel)),
    [workAreaProposals],
  );

  /** Chip azul (RAG): recuperar desde localStorage tras login o cuando llegan propuestas desde S3/restore. */
  useEffect(() => {
    const uid = connect?.usuario?.trim() || getUserId()?.trim();
    const stored = uid ? loadWorkspaceTaskContext(uid) : null;
    const hu = taskContext?.huCode?.trim() || stored?.huCode?.trim();
    if (!uid || !hu) return;
    setWorkAreaProposals((prev) => {
      if (prev.length === 0) return prev;
      let changed = false;
      const next = prev.map((p) => {
        if (!p.acceptedRelativePath || p.vectorIndexed) return p;
        const loaded = loadWorkAreaIndexed(uid, hu, p.acceptedRelativePath);
        if (!loaded) return p;
        changed = true;
        return { ...p, vectorIndexed: true, lastIndexedChunks: loaded.chunksIndexed };
      });
      return changed ? next : prev;
    });
  }, [connect?.usuario, taskContext?.huCode, workAreaProposals.length]);

  useEffect(() => {
    if (!workAreaNotice) return;
    const t = window.setTimeout(() => setWorkAreaNotice(null), 6000);
    return () => clearTimeout(t);
  }, [workAreaNotice]);

  useEffect(() => {
    setWorkAreaS3Editing(false);
    setWorkAreaS3EditDraft("");
    setWorkAreaCloneDraftEditing(false);
    setWorkAreaCloneDraftBuffer("");
  }, [workAreaSelectedId]);

  useEffect(() => {
    if (workAreaPanelProposals.length > 0) return;
    setFileViewSource((s) => (s === "workarea" ? "repo" : s));
  }, [workAreaPanelProposals.length]);

  async function handleWorkAreaAccept(id: string) {
    const p = workAreaProposals.find((x) => x.id === id);
    if (!p?.draftRelativePath) return;
    setWorkAreaErr(null);
    setWorkAreaKeepLoadingId(id);
    try {
      const r = await acceptWorkAreaDraft(p.draftRelativePath, workAreaTaskHeaders);
      setWorkAreaProposals((prev) =>
        prev.map((x) => (x.id === id ? workAreaProposalAfterAccept(x, r.acceptedRelativePath) : x)),
      );
      setWorkAreaNotice(
        `Aceptado: ${r.acceptedRelativePath} — prueba el archivo en el clon; luego «Indexar borrador».`,
      );
    } catch (e) {
      setWorkAreaErr(e instanceof Error ? e.message : String(e));
    } finally {
      setWorkAreaKeepLoadingId(null);
    }
  }

  const startWorkAreaCloneDraftEdit = useCallback(() => {
    const p = workAreaProposals.find((x) => x.id === workAreaSelectedId);
    if (!p?.draftRelativePath || p.artifactViewOnly) return;
    let t = p.content ?? "";
    if (hasDocvizMergeMarkers(t)) {
      t = workAreaResolvedDraft ?? buildResolvedDocvizMerge(t, "theirs");
    }
    setWorkAreaCloneDraftBuffer(t);
    setWorkAreaCloneDraftEditing(true);
  }, [workAreaProposals, workAreaResolvedDraft, workAreaSelectedId]);

  const cancelWorkAreaCloneDraftEdit = useCallback(() => {
    setWorkAreaCloneDraftEditing(false);
  }, []);

  /** Guarda el texto mostrado/resuelto en la vista (no solo el .txt en disco) y lo mueve a workarea en S3. */
  async function handleWorkAreaSaveFinalize(id: string) {
    const p = workAreaProposals.find((x) => x.id === id);
    if (!p?.draftRelativePath) return;
    setWorkAreaErr(null);
    setWorkAreaKeepLoadingId(id);
    try {
      let text: string;
      if (workAreaCloneDraftEditing && p.id === workAreaSelectedId) {
        text = workAreaCloneDraftBuffer;
      } else if (hasDocvizMergeMarkers(p.content)) {
        text = workAreaResolvedDraft ?? buildResolvedDocvizMerge(p.content, "theirs");
      } else if (hasGitConflictMarkers(p.content) && workAreaConflictViewerRef.current) {
        if (workAreaConflictViewerRef.current.hasPendingConflicts()) {
          setWorkAreaErr("Resuelve o rechaza cada bloque de conflicto antes de guardar en workarea.");
          return;
        }
        text = workAreaConflictViewerRef.current.getResolvedText();
      } else {
        text = p.content ?? "";
      }
      if (hasDocvizMergeMarkers(text) || hasGitConflictMarkers(text)) {
        setWorkAreaErr("Aún hay marcadores de conflicto sin resolver.");
        return;
      }
      const r = await finalizeWorkAreaDraft(
        { draftRelativePath: p.draftRelativePath, finalContent: text },
        workAreaTaskHeaders,
      );
      setWorkAreaProposals((prev) =>
        prev.map((x) => (x.id === id ? workAreaProposalAfterAccept(x, r.acceptedRelativePath) : x)),
      );
      setWorkAreaNotice(
        `Guardado en workarea: ${r.acceptedRelativePath} — revisa el clon; luego «Indexar borrador» si quieres RAG.`,
      );
      setWorkAreaCloneDraftEditing(false);
    } catch (e) {
      setWorkAreaErr(e instanceof Error ? e.message : String(e));
    } finally {
      setWorkAreaKeepLoadingId(null);
    }
  }

  async function handleWorkAreaApplyMergeFinal(id: string) {
    const p = workAreaProposals.find((x) => x.id === id);
    if (!p?.sourcePath || p.draftVersion == null || !p.content) return;
    const revised = hasDocvizMergeMarkers(p.content)
      ? workAreaResolvedDraft ?? buildResolvedDocvizMerge(p.content, "theirs")
      : extractRevisedFromMergeMarkers(p.content) ?? p.content;
    if (!revised.trim()) {
      setWorkAreaErr("El contenido propuesto está vacío.");
      return;
    }
    setWorkAreaErr(null);
    setWorkAreaKeepLoadingId(id);
    try {
      const r = await applyWorkAreaFinal(
        {
          sourcePath: p.sourcePath,
          draftVersion: p.draftVersion,
          finalContent: revised,
        },
        workAreaTaskHeaders,
      );
      setWorkAreaProposals((prev) =>
        prev.map((x) => (x.id === id ? workAreaProposalAfterAccept(x, r.acceptedRelativePath) : x)),
      );
      setWorkAreaNotice(
        `Aplicado: ${r.acceptedRelativePath} — revisa el clon; luego «Indexar borrador» si quieres RAG.`,
      );
    } catch (e) {
      setWorkAreaErr(e instanceof Error ? e.message : String(e));
    } finally {
      setWorkAreaKeepLoadingId(null);
    }
  }

  async function handleWorkAreaIndexDraft(id: string) {
    const p = workAreaProposals.find((x) => x.id === id);
    if (!p?.acceptedRelativePath) return;
    setWorkAreaErr(null);
    setWorkAreaKeepLoadingId(id);
    try {
      const r = await indexWorkAreaFileFromPath(p.acceptedRelativePath, workAreaTaskHeaders);
      const uid = connect?.usuario?.trim() || getUserId()?.trim();
      const stored = uid ? loadWorkspaceTaskContext(uid) : null;
      const hu = taskContext?.huCode?.trim() || stored?.huCode?.trim();
      if (uid && hu) {
        saveWorkAreaIndexed(uid, hu, p.acceptedRelativePath, r.chunksIndexed);
      }
      setWorkAreaProposals((prev) =>
        prev.map((x) =>
          x.id === id
            ? { ...x, vectorIndexed: true, lastIndexedChunks: r.chunksIndexed }
            : x,
        ),
      );
      setWorkAreaNotice(`Indexado (${r.chunksIndexed} fragmentos): ${p.acceptedRelativePath}`);
    } catch (e) {
      setWorkAreaErr(e instanceof Error ? e.message : String(e));
    } finally {
      setWorkAreaKeepLoadingId(null);
    }
  }

  async function handleWorkAreaAcceptAll() {
    const pending = workAreaProposals.filter((p) => p.draftRelativePath);
    if (pending.length === 0) return;
    setWorkAreaErr(null);
    setWorkAreaKeepLoadingId("__all__");
    try {
      const r = await acceptAllWorkAreaDrafts(pending.map((p) => p.draftRelativePath!), workAreaTaskHeaders);
      const paths = r.acceptedRelativePaths;
      setWorkAreaProposals((prev) =>
        prev.map((x) => {
          const pi = pending.findIndex((q) => q.id === x.id);
          if (pi < 0) return x;
          const acc = paths[pi];
          const fn = acc.includes("/") ? acc.slice(acc.lastIndexOf("/") + 1) : acc;
          const dot = fn.lastIndexOf(".");
          return {
            ...x,
            acceptedRelativePath: acc,
            draftRelativePath: undefined,
            content: "",
            diffLines: undefined,
            vectorIndexed: undefined,
            lastIndexedChunks: undefined,
            fileName: fn,
            extension: dot > 0 ? fn.slice(dot + 1) : "",
          };
        }),
      );
      setWorkAreaNotice(
        `${paths.length} borrador(es) aceptado(s). Revisa los archivos en el clon; indexa cuando quieras.`,
      );
    } catch (e) {
      setWorkAreaErr(e instanceof Error ? e.message : String(e));
    } finally {
      setWorkAreaKeepLoadingId(null);
    }
  }

  async function handleWorkAreaDismiss(id: string) {
    const p = workAreaProposals.find((x) => x.id === id);
    setWorkAreaErr(null);
    try {
      if (p?.draftRelativePath) {
        await deleteWorkAreaDraft(p.draftRelativePath, workAreaTaskHeaders);
      }
    } catch {
      /* ignore */
    }
    setWorkAreaProposals((prev) => prev.filter((x) => x.id !== id));
  }

  const handleWorkAreaDeleteS3Artifact = useCallback(
    async (p: WorkAreaFileProposal) => {
      if (!p.s3Bucket?.trim() || !p.s3ObjectKey?.trim()) return;
      if (!window.confirm(`¿Eliminar "${p.fileName}" del bucket ${p.s3Bucket}?`)) return;
      setWorkAreaErr(null);
      setWorkAreaKeepLoadingId(p.id);
      try {
        await deleteWorkAreaS3Artifact(p.s3Bucket, p.s3ObjectKey, workAreaTaskHeaders);
        workAreaDraftFetchKeysRef.current.clear();
        setWorkAreaProposals((prev) => prev.filter((x) => x.id !== p.id));
        setWorkAreaSelectedId((cur) => (cur === p.id ? null : cur));
        setWorkAreaS3Editing(false);
        setWorkAreaS3EditDraft("");
        setWorkAreaNotice(`Eliminado de S3: ${p.fileName}`);
      } catch (e) {
        setWorkAreaErr(e instanceof Error ? e.message : String(e));
      } finally {
        setWorkAreaKeepLoadingId(null);
      }
    },
    [workAreaTaskHeaders],
  );

  const handleWorkAreaToolbarDownloadS3 = useCallback(async () => {
    const p = workAreaProposals.find((x) => x.id === workAreaSelectedId);
    if (!p?.s3Bucket?.trim() || !p.s3ObjectKey?.trim()) return;
    setWorkAreaErr(null);
    try {
      let text = (p.content ?? "").trim();
      if (!text) {
        text = await fetchWorkAreaS3ArtifactBody(p.s3Bucket, p.s3ObjectKey, workAreaTaskHeaders);
      }
      if (hasDocvizMergeMarkers(text)) {
        text = workAreaResolvedDraft ?? buildResolvedDocvizMerge(text, "theirs");
      }
      const blob = new Blob([text], { type: "text/plain;charset=utf-8" });
      const url = URL.createObjectURL(blob);
      const a = document.createElement("a");
      a.href = url;
      a.download = p.fileName?.trim() || "archivo.txt";
      a.rel = "noopener";
      document.body.appendChild(a);
      a.click();
      a.remove();
      URL.revokeObjectURL(url);
    } catch (e) {
      setWorkAreaErr(e instanceof Error ? e.message : String(e));
    }
  }, [workAreaProposals, workAreaResolvedDraft, workAreaSelectedId, workAreaTaskHeaders]);

  const startWorkAreaS3Edit = useCallback(() => {
    const p = workAreaProposals.find((x) => x.id === workAreaSelectedId);
    if (!p || !isEditableS3Artifact(p)) return;
    let draft = p.content ?? "";
    if (hasDocvizMergeMarkers(draft)) {
      draft = workAreaResolvedDraft ?? buildResolvedDocvizMerge(draft, "theirs");
    }
    setWorkAreaS3EditDraft(draft);
    setWorkAreaS3Editing(true);
  }, [workAreaProposals, workAreaResolvedDraft, workAreaSelectedId]);

  const cancelWorkAreaS3Edit = useCallback(() => {
    setWorkAreaS3Editing(false);
  }, []);

  const saveWorkAreaS3Edit = useCallback(async () => {
    const p = workAreaProposals.find((x) => x.id === workAreaSelectedId);
    if (!p?.s3ObjectKey?.trim() || !p.s3Bucket?.trim() || !isEditableS3Artifact(p)) return;
    const finalText = workAreaS3EditDraft;
    if (
      hasDocvizMergeMarkers(finalText) ||
      hasGitConflictMarkers(finalText)
    ) {
      setWorkAreaErr("Quita los marcadores de conflicto del texto antes de guardar.");
      return;
    }
    setWorkAreaErr(null);
    setWorkAreaKeepLoadingId(p.id);
    try {
      if (isWorkareaS3Artifact(p)) {
        const r = await saveWorkAreaS3WorkareaAndReindex(
          { objectKey: p.s3ObjectKey, content: finalText },
          workAreaTaskHeaders,
        );
        const uid = connect?.usuario?.trim() || getUserId()?.trim();
        const stored = uid ? loadWorkspaceTaskContext(uid) : null;
        const hu = taskContext?.huCode?.trim() || stored?.huCode?.trim();
        const storagePath = `__s3_workarea__/${p.fileName}`;
        if (uid && hu) {
          saveWorkAreaIndexed(uid, hu, storagePath, r.chunksIndexed ?? 0);
        }
        setWorkAreaProposals((prev) =>
          prev.map((x) =>
            x.id === p.id
              ? {
                  ...x,
                  content: finalText,
                  vectorIndexed: true,
                  lastIndexedChunks: r.chunksIndexed,
                }
              : x,
          ),
        );
        setWorkAreaNotice(`Guardado en S3 y reindexado (${r.chunksIndexed ?? 0} fragmentos): ${p.fileName}`);
      } else {
        await saveWorkAreaS3BorradorContent(
          { objectKey: p.s3ObjectKey, content: finalText },
          workAreaTaskHeaders,
        );
        setWorkAreaProposals((prev) =>
          prev.map((x) =>
            x.id === p.id
              ? {
                  ...x,
                  content: finalText,
                }
              : x,
          ),
        );
        setWorkAreaNotice(`Borrador guardado en S3: ${p.fileName}`);
      }
      setWorkAreaS3Editing(false);
    } catch (e) {
      setWorkAreaErr(e instanceof Error ? e.message : String(e));
    } finally {
      setWorkAreaKeepLoadingId(null);
    }
  }, [
    workAreaProposals,
    workAreaSelectedId,
    workAreaS3EditDraft,
    workAreaTaskHeaders,
    connect?.usuario,
    taskContext?.huCode,
  ]);

  const onQuestionDrop = useCallback(
    (e: React.DragEvent<HTMLTextAreaElement>) => {
      e.preventDefault();
      if (!ingestComplete) return;
      const token = getDocvizFileMentionFromDataTransfer(e.dataTransfer);
      if (!token) return;
      const ta = e.currentTarget;
      const start = ta.selectionStart ?? 0;
      const end = ta.selectionEnd ?? 0;
      setQuestion((prev) => {
        const before = prev.slice(0, start);
        const after = prev.slice(end);
        const needsSpace = before.length > 0 && !/\s$/.test(before);
        const insert = (needsSpace ? " " : "") + token;
        const next = before + insert + after;
        const cursorPos = before.length + insert.length;
        window.setTimeout(() => {
          ta.focus();
          ta.setSelectionRange(cursorPos, cursorPos);
        }, 0);
        return next;
      });
    },
    [ingestComplete],
  );

  const [chatTurns, setChatTurns] = useState<ChatHistoryEntry[]>([]);

  /** Base (BD / HU / sessionStorage); el hilo mostrado para tarea usa además el menor N en Firestore. */
  const baseChatConversationId = useMemo(
    () =>
      resolveChatConversationId(connect?.usuario ?? getUserId() ?? undefined, taskContext?.huCode, {
        persistedConversationId: taskContext?.chatConversationId,
        taskId: taskContext?.taskId,
        cellName: taskContext?.cellLabel,
      }),
    [
      connect?.usuario,
      taskContext?.huCode,
      taskContext?.chatConversationId,
      taskContext?.taskId,
      taskContext?.cellLabel,
    ],
  );

  const [resolvedPrimaryChatId, setResolvedPrimaryChatId] = useState<string | null>(null);

  useEffect(() => {
    setResolvedPrimaryChatId(null);
  }, [taskContext?.taskId, taskContext?.huCode]);

  const chatConversationId = resolvedPrimaryChatId ?? baseChatConversationId;

  const [chatHistoryErr, setChatHistoryErr] = useState<string | null>(null);

  /** Evita el primer envío automático al modelo antes de saber si Firestore ya tiene turnos. */
  const [chatHistoryHydrated, setChatHistoryHydrated] = useState(false);

  const [chatErr, setChatErr] = useState<string | null>(null);

  const [chatLoading, setChatLoading] = useState(false);

  const chatFormRef = useRef<HTMLFormElement>(null);

  const onQuestionKeyDown = useCallback(
    (e: KeyboardEvent<HTMLTextAreaElement>) => {
      if (e.key !== "Enter" || e.shiftKey) return;
      e.preventDefault();
      if (!ingestComplete || chatLoading) return;
      const q = question.trim();
      if (!q) return;
      chatFormRef.current?.requestSubmit();
    },
    [ingestComplete, chatLoading, question],
  );

  /**
   * Primer mensaje RAG automático (tarea nueva o reanudar con historial vacío).
   * `sessionDedupeKey` evita doble envío en la misma pestaña; `isCancelled` limpia al desmontar o cambiar tarea.
   */
  const runAutoInitialChatStream = useCallback(
    async (prompt: string, sessionDedupeKey: string, isCancelled: () => boolean) => {
      let storageKey = sessionDedupeKey;
      try {
        if (sessionStorage.getItem(sessionDedupeKey)) return;
        sessionStorage.setItem(sessionDedupeKey, "1");
      } catch {
        storageKey = "";
      }
      if (isCancelled()) return;
      setChatErr(null);
      setChatLoading(true);
      const streamId = `stream-task-${Date.now()}`;
      setChatTurns((prev) => [
        ...prev,
        {
          id: streamId,
          question: prompt,
          answer: "",
          sources: [],
          repoLabel: "",
          createdAt: new Date().toISOString(),
        },
      ]);
      try {
        let convForChat = baseChatConversationId;
        if (taskContext?.taskId != null && taskContext?.huCode?.trim()) {
          const r = await fetchChatHistory(50, {
            taskId: taskContext.taskId,
            huCode: taskContext.huCode,
            ...(taskContext.cellLabel?.trim() ? { cellName: taskContext.cellLabel.trim() } : {}),
          });
          if (isCancelled()) return;
          if (r.resolvedConversationId) {
            setResolvedPrimaryChatId(r.resolvedConversationId);
            convForChat = r.resolvedConversationId;
          }
        }
        await streamVectorChat(
          prompt,
          {
            onStart: (sources) => {
              setChatTurns((prev) => prev.map((t) => (t.id === streamId ? { ...t, sources } : t)));
            },
            onDelta: (text) => {
              setChatTurns((prev) =>
                prev.map((t) => (t.id === streamId ? { ...t, answer: t.answer + text } : t)),
              );
            },
            onProposals: onWorkAreaChatProposals,
          },
          {
            taskHuCode: taskContext?.huCode,
            ...(taskContext?.taskId != null ? { taskId: taskContext.taskId } : {}),
            ...(convForChat ? { conversationId: convForChat } : {}),
            ...(taskContext?.cellLabel?.trim() ? { cellName: taskContext.cellLabel.trim() } : {}),
          },
        );
        if (isCancelled()) return;
        try {
          const { entries: rows } =
            taskContext?.taskId != null && taskContext?.huCode?.trim()
              ? await fetchChatHistory(50, {
                  taskId: taskContext.taskId,
                  huCode: taskContext.huCode,
                  ...(taskContext.cellLabel?.trim() ? { cellName: taskContext.cellLabel.trim() } : {}),
                })
              : await fetchChatHistory(50, { conversationId: convForChat });
          setChatHistoryErr(null);
          setChatTurns((prev) => {
            const local = prev.find((t) => t.id === streamId);
            return mergeFirestoreHistoryWithLocalStream(rows, local, prompt);
          });
        } catch {
          /* igual que onChat */
        }
      } catch (e) {
        if (!isCancelled()) {
          setChatErr(e instanceof Error ? e.message : String(e));
          if (storageKey) {
            try {
              sessionStorage.removeItem(storageKey);
            } catch {
              /* ignore */
            }
          }
        }
      } finally {
        if (!isCancelled()) setChatLoading(false);
      }
    },
    [
      baseChatConversationId,
      taskContext?.taskId,
      taskContext?.huCode,
      taskContext?.cellLabel,
      onWorkAreaChatProposals,
    ],
  );

  /** Panel lateral (sesión + índice); persistido para la próxima visita */
  const [sessionPanelOpen, setSessionPanelOpen] = useState(() => {
    try {
      return localStorage.getItem("docviz_session_panel_open") !== "0";
    } catch {
      return true;
    }
  });

  const [logoutLoading, setLogoutLoading] = useState(false);

  const [logoutErr, setLogoutErr] = useState<string | null>(null);

  const [ingestRetry, setIngestRetry] = useState(0);

  const reconnectFromSaved = useCallback(async () => {
    const saved = loadGitConnectRequest();
    if (!saved) {
      navigate("/connect", { state: { vcs: "GIT" as const } });
      return;
    }
    setReconnectLoading(true);
    setChatErr(null);
    try {
      const res = await connectGit(saved);
      setConnect(res);
      initialIngestFromConnect.current = undefined;
      setIngestComplete(false);
      setIngestResult(null);
      setIngestRetry((n) => n + 1);
    } catch (e) {
      setChatErr(e instanceof Error ? e.message : String(e));
    } finally {
      setReconnectLoading(false);
    }
  }, [navigate]);

  const [omitidosOpen, setOmitidosOpen] = useState(true);

  const [fileViewSource, setFileViewSource] = useState<FileViewSource>("repo");

  useEffect(() => {
    setWorkAreaResolvedDraft(null);
  }, [workAreaSelectedId]);

  useEffect(() => {
    if (fileViewSource !== "workarea" || !workAreaSelectedId) return;
    const p = workAreaPanelProposals.find((x) => x.id === workAreaSelectedId);
    if (!p) return;
    const canS3Body = Boolean(p.s3Bucket?.trim() && p.s3ObjectKey?.trim());
    const canPresign = Boolean(p.s3PresignedUrl?.trim());
    const canDraftPath = Boolean(p.draftRelativePath?.trim());
    if (!canS3Body && !canPresign && !canDraftPath) return;
    const hasPreview =
      (p.content != null && p.content.trim().length > 0) ||
      (p.diffLines != null && p.diffLines.length > 0);
    if (hasPreview) return;
    const key = `${p.id}\0${p.s3Bucket ?? ""}\0${p.s3ObjectKey ?? ""}\0${p.draftRelativePath ?? ""}\0${p.s3PresignedUrl ?? ""}`;
    if (workAreaDraftFetchKeysRef.current.has(key)) return;
    setWorkAreaPreviewLoadingId(p.id);
    const ac = new AbortController();
    const run = async () => {
      try {
        if (p.s3Bucket?.trim() && p.s3ObjectKey?.trim()) {
          const text = await fetchWorkAreaS3ArtifactBody(p.s3Bucket, p.s3ObjectKey, {
            signal: ac.signal,
            ...(workAreaTaskHeaders ?? {}),
          });
          workAreaDraftFetchKeysRef.current.add(key);
          setWorkAreaProposals((prev) => prev.map((x) => (x.id === p.id ? { ...x, content: text } : x)));
          return;
        }
        if (p.s3PresignedUrl?.trim()) {
          const text = await fetchTextFromPresignedUrl(p.s3PresignedUrl, { signal: ac.signal });
          workAreaDraftFetchKeysRef.current.add(key);
          setWorkAreaProposals((prev) => prev.map((x) => (x.id === p.id ? { ...x, content: text } : x)));
          return;
        }
        if (p.draftRelativePath) {
          const r = await fetchWorkAreaDraftContent(p.draftRelativePath, {
            signal: ac.signal,
            ...(workAreaTaskHeaders ?? {}),
          });
          workAreaDraftFetchKeysRef.current.add(key);
          setWorkAreaProposals((prev) => prev.map((x) => (x.id === p.id ? { ...x, content: r.content } : x)));
        }
      } catch {
        /* abort o red */
      } finally {
        setWorkAreaPreviewLoadingId((cur) => (cur === p.id ? null : cur));
      }
    };
    void run();
    return () => ac.abort();
  }, [fileViewSource, workAreaSelectedId, workAreaPanelProposals, workAreaTaskHeaders]);

  const [selectedSupportId, setSelectedSupportId] = useState<string | null>(null);

  const [supportEditing, setSupportEditing] = useState(false);

  const focusWorkAreaProposal = useCallback((id: string) => {
    setWorkAreaSelectedId(id);
    setFileViewSource("workarea");
    setSelectedPath(null);
    setFileContent(null);
    setFileErr(null);
    setSelectedSupportId(null);
    setSupportEditing(false);
  }, []);

  useEffect(() => {
    const len = workAreaPanelProposals.length;
    const prevLen = prevWorkAreaProposalCountRef.current;

    if (len === 0) {
      setWorkAreaSelectedId(null);
      prevWorkAreaProposalCountRef.current = 0;
      return;
    }

    if (len > prevLen) {
      const last = workAreaPanelProposals[len - 1];
      if (last) {
        focusWorkAreaProposal(last.id);
      }
      prevWorkAreaProposalCountRef.current = len;
      return;
    }

    setWorkAreaSelectedId((cur) => {
      if (cur && workAreaPanelProposals.some((p) => p.id === cur)) return cur;
      if (cur == null) return null;
      return workAreaPanelProposals[len - 1]?.id ?? null;
    });
    prevWorkAreaProposalCountRef.current = len;
  }, [workAreaPanelProposals, focusWorkAreaProposal]);

  function onSelectWorkAreaChip(id: string) {
    focusWorkAreaProposal(id);
  }

  const [supportDraft, setSupportDraft] = useState("");

  const [supportUploadUi, setSupportUploadUi] = useState<SupportUploadUiState>({ kind: "idle" });

  const {
    gridRef,
    cols,
    isResizable,
    onMouseDownLeft,
    onMouseDownRight,
    resetWidths,
  } = useWorkspaceColumnWidths();

  const filePreviewLru = useRef<Map<string, string>>(new Map());



  const { docs: supportDocs, add: addSupportDoc, update: updateSupportDoc, remove: removeSupportDoc } =

    useSupportDocuments(connect?.usuario ?? "");

  const supportPanelDocs = isSupportRole() ? serverSupportDocs : supportDocs;

  useEffect(() => {
    if (!isSupportRole() || taskCellRepoId == null) {
      setServerSupportDocs([]);
      return;
    }
    let cancelled = false;
    void listSupportMarkdownObjects(taskCellRepoId)
      .then((rows) => {
        if (cancelled) return;
        setServerSupportDocs(
          rows.map((o) => ({
            id: o.fileName,
            name: o.fileName,
            content: "",
            updatedAt: Date.now(),
            storageFileName: o.fileName,
            s3Url: o.url,
          })),
        );
      })
      .catch(() => {
        if (!cancelled) setServerSupportDocs([]);
      });
    return () => {
      cancelled = true;
    };
  }, [taskCellRepoId]);

  useEffect(() => {

    if (state?.connect) return;

    const saved = loadGitConnectRequest();

    if (!saved) {

      navigate("/", { replace: true });

      return;

    }

    let cancelled = false;

    (async () => {

      try {

        const res = await connectGit(saved);

        if (cancelled) return;

        setConnect(res);

        setRestorePhase("idle");

      } catch {

        if (cancelled) return;

        navigate("/", { replace: true });

      }

    })();

    return () => {

      cancelled = true;

    };

  }, [navigate, state?.connect]);



  useEffect(() => {

    try {

      localStorage.setItem("docviz_session_panel_open", sessionPanelOpen ? "1" : "0");

    } catch {

      /* ignore */

    }

  }, [sessionPanelOpen]);

  /** Panel lateral derecho (Soporte .md) */
  const [supportRailOpen, setSupportRailOpen] = useState(() => {
    try {
      return localStorage.getItem("docviz_support_rail_open") !== "0";
    } catch {
      return true;
    }
  });

  useEffect(() => {
    try {
      localStorage.setItem("docviz_support_rail_open", supportRailOpen ? "1" : "0");
    } catch {
      /* ignore */
    }
  }, [supportRailOpen]);

  useEffect(() => {

    if (selectedSupportId && !supportPanelDocs.some((d) => d.id === selectedSupportId)) {

      setSelectedSupportId(null);

      setFileViewSource("repo");

      setSupportEditing(false);

    }

  }, [supportPanelDocs, selectedSupportId]);



  /** Ingesta automática al mostrar el contexto maestro (una vez por carga del workspace). */

  useEffect(() => {

    if (ingestRetry === 0 && initialIngestFromConnect.current) {
      return () => {};
    }

    if (!connect?.directory) return;

    let cancelled = false;

    const abortIngest = new AbortController();

    setIngestErr(null);

    setIngestResult(null);

    setIngestComplete(false);

    setIngestLoading(true);

    setIngestProgress({
      totalFiles: 0,
      filesProcessed: 0,
      chunksIndexed: 0,
      currentFile: null,
      detail: null,
      mode: "stream",
    });

    async function runAutoIngest() {

      try {

        const r = await vectorIngestStream(
          (ev) => {
            if (cancelled) return;
            if (ev.phase === "START" && ev.totalFiles != null) {
              setIngestProgress({
                totalFiles: ev.totalFiles,
                filesProcessed: 0,
                chunksIndexed: 0,
                currentFile: null,
                detail: null,
                mode: "stream",
              });
            }
            if (ev.phase === "FILE" || ev.phase === "PROGRESS") {
              setIngestProgress((prev) => ({
                totalFiles: ev.totalFiles ?? prev?.totalFiles ?? 0,
                filesProcessed: ev.filesProcessed ?? 0,
                chunksIndexed: ev.chunksIndexed ?? 0,
                currentFile: ev.currentFile ?? null,
                detail: ev.detail ?? null,
                mode: "stream",
              }));
            }
          },
          { signal: abortIngest.signal },
        );

        if (cancelled) return;

        setIngestResult({
          filesProcessed: r.filesProcessed,
          chunksIndexed: r.chunksIndexed,
          namespace: r.namespace,
          skipped: r.skipped ?? [],
        });

        setIngestComplete(true);
      } catch (e) {
        if (cancelled) return;
        if (e instanceof Error && e.name === "AbortError") return;
        setIngestErr(e instanceof Error ? e.message : String(e));
      } finally {
        if (!cancelled) {
          setIngestLoading(false);
          setIngestProgress(null);
        }
      }
    }

    void runAutoIngest();

    return () => {
      cancelled = true;
      abortIngest.abort();
    };
  }, [connect?.directory, ingestRetry]);



  /**
   * Historial Firestore: no depende de la ingesta vectorial (índice RAG). Antes el chat quedaba vacío si
   * POST /vector/ingest fallaba o no terminaba; el historial debe cargarse con solo usuario + conversación.
   */
  useEffect(() => {
    if (!getUserId()?.trim()) return;
    let cancelled = false;
    setChatHistoryHydrated(false);
    (async () => {
      try {
        setChatHistoryErr(null);
        if (taskContext?.taskId != null && taskContext?.huCode?.trim()) {
          const { entries, resolvedConversationId } = await fetchChatHistory(50, {
            taskId: taskContext.taskId,
            huCode: taskContext.huCode,
            ...(taskContext.cellLabel?.trim() ? { cellName: taskContext.cellLabel.trim() } : {}),
          });
          if (!cancelled) {
            if (resolvedConversationId) setResolvedPrimaryChatId(resolvedConversationId);
            setChatTurns(entries);
          }
        } else {
          if (!baseChatConversationId) {
            if (!cancelled) setChatHistoryHydrated(true);
            return;
          }
          const { entries } = await fetchChatHistory(50, { conversationId: baseChatConversationId });
          if (!cancelled) setChatTurns(entries);
        }
      } catch (e) {
        if (!cancelled) {
          setChatHistoryErr(e instanceof Error ? e.message : String(e));
        }
      } finally {
        if (!cancelled) setChatHistoryHydrated(true);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [
    ingestRetry,
    baseChatConversationId,
    taskContext?.taskId,
    taskContext?.huCode,
    taskContext?.cellLabel,
    connect?.usuario,
  ]);

  /**
   * Tras conectar + indexar: recupera borradores/workarea desde S3 (misma convención que el sync al guardar).
   * Incluye `connect.directory` en la clave para volver a ejecutar tras «Reconectar» (nuevo clon).
   * No exige taskId: basta código HU guardado en sesión para rutas workarea/{usuario}/{HU}/.
   */
  useEffect(() => {
    const hu = taskContext?.huCode?.trim();
    if (!ingestComplete || !connect?.directory || hu == null) return;
    const cell = taskContext?.cellLabel?.trim();
    const key = `${connect.directory}\0${hu}\0${cell ?? ""}`;
    if (taskArtifactRestoreKeyRef.current === key) return;
    let cancelled = false;
    void (async () => {
      try {
        const r = await restoreWorkAreaFromS3({ taskHuCode: hu, cellLabel: cell });
        if (cancelled) return;
        if (r.proposals?.length) {
          mergeWorkAreaProposals(mapRestoredProposals(r.proposals));
        }
      } catch {
        /* S3 deshabilitado, sin cabeceras HU o error de red */
      }
      try {
        if (cancelled) return;
        await refreshWorkAreaS3List();
      } catch {
        /* listado opcional */
      } finally {
        if (!cancelled) {
          taskArtifactRestoreKeyRef.current = key;
        }
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [
    ingestComplete,
    connect?.directory,
    taskContext?.huCode,
    taskContext?.cellLabel,
    mergeWorkAreaProposals,
    refreshWorkAreaS3List,
  ]);

  /** Primer mensaje automático solo al crear una tarea nueva (`initialChatPrompt` en el state de la ruta). */
  useEffect(() => {
    if (!ingestComplete || !initialChatPromptFromTask) return;
    const dedupe =
      taskContext?.taskId != null
        ? `docviz:autoTaskChat:${connect?.usuario ?? "u"}:task-${taskContext.taskId}`
        : `docviz:autoTaskChat:${connect?.usuario ?? "u"}:p-${initialChatPromptFromTask.slice(0, 96)}`;
    let cancelled = false;
    void runAutoInitialChatStream(initialChatPromptFromTask, dedupe, () => cancelled);
    return () => {
      cancelled = true;
      setChatLoading(false);
    };
  }, [ingestComplete, initialChatPromptFromTask, connect?.usuario, taskContext?.taskId, runAutoInitialChatStream]);

  /**
   * «Continuar en workspace» sin prompt en la ruta: si tras cargar Firestore no hay turnos,
   * se obtiene el prompt desde el backend y se envía una vez (primer enunciado aún no procesado).
   */
  useEffect(() => {
    if (!ingestComplete || !resumeWorkspaceChat || !chatHistoryHydrated) return;
    if (chatTurns.length > 0) return;
    if (!taskContext?.taskId) return;
    let cancelled = false;
    void (async () => {
      try {
        const cont = await continueTask(taskContext.taskId!);
        if (cancelled) return;
        const prompt = cont.initialChatPrompt?.trim();
        if (!prompt) return;
        const dedupe = `docviz:autoResumeFirst:${taskContext.taskId}`;
        await runAutoInitialChatStream(prompt, dedupe, () => cancelled);
      } catch (e) {
        if (!cancelled) {
          setChatErr(e instanceof Error ? e.message : String(e));
        }
      }
    })();
    return () => {
      cancelled = true;
      setChatLoading(false);
    };
  }, [
    ingestComplete,
    resumeWorkspaceChat,
    chatHistoryHydrated,
    chatTurns.length,
    taskContext?.taskId,
    runAutoInitialChatStream,
  ]);



  async function onSelectFile(rel: string) {

    setFileViewSource("repo");

    setWorkAreaSelectedId(null);

    setSelectedSupportId(null);

    setSupportEditing(false);

    setSelectedPath(rel);

    setFileErr(null);

    const cached = lruMapGet(filePreviewLru.current, rel);

    if (cached !== undefined) {

      setFileContent(cached);

      return;

    }

    setFileContent(null);

    try {

      const r = await fetchFileContent(rel);

      lruMapPut(filePreviewLru.current, rel, r.content, FILE_PREVIEW_LRU_MAX);

      setFileContent(r.content);

    } catch (e) {

      setFileErr(e instanceof Error ? e.message : String(e));

    }

  }



  function onSelectSupport(id: string) {

    setFileViewSource("support");

    setWorkAreaSelectedId(null);

    setSelectedSupportId(id);

    setSelectedPath(null);

    setFileContent(null);

    setFileErr(null);

    setSupportEditing(false);

    const doc = supportPanelDocs.find((d) => d.id === id);

    if (isSupportRole() && taskCellRepoId != null && doc && !doc.content && doc.s3Url) {
      void (async () => {
        try {
          const text = await fetchTextFromPresignedUrl(doc.s3Url!);
          setServerSupportDocs((prev) =>
            prev.map((d) => (d.id === id ? { ...d, content: text, updatedAt: Date.now() } : d)),
          );
          setSupportDraft(text);
        } catch (e) {
          setFileErr(e instanceof Error ? e.message : String(e));
          setSupportDraft("");
        }
      })();
      setSupportDraft("");
      return;
    }

    setSupportDraft(doc?.content ?? "");

  }



  async function handleSupportUpload(file: File, content: string) {

    if (isSupportRole()) return;

    let objectKey: string | undefined;
    let storageFileName: string | undefined;

    setSupportUploadUi({ kind: "busy", phase: "s3" });

    const toEmbedding = window.setTimeout(() => {
      setSupportUploadUi((u) => (u.kind === "busy" ? { kind: "busy", phase: "embedding" } : u));
    }, 900);

    try {

      const res = await uploadSupportMarkdown(file);

      window.clearTimeout(toEmbedding);

      objectKey = res.objectKey;
      storageFileName = res.fileName;

      setSupportUploadUi({
        kind: "done",
        bucket: res.bucket,
        objectKey: res.objectKey,
        chunksIndexed: res.chunksIndexed,
      });

      window.setTimeout(() => setSupportUploadUi({ kind: "idle" }), 12_000);

    } catch (e) {

      window.clearTimeout(toEmbedding);

      const msg = e instanceof Error ? e.message : String(e);

      if (msg === SUPPORT_UPLOAD_API_UNAVAILABLE) {
        setSupportUploadUi({ kind: "local_only" });
      } else {
        setSupportUploadUi({
          kind: "error",
          message: msg || "No se pudo subir el Markdown",
        });
      }

      window.setTimeout(() => setSupportUploadUi({ kind: "idle" }), 10_000);

    }

    const id = addSupportDoc(file.name, content, { objectKey, storageFileName });

    setFileViewSource("support");

    setWorkAreaSelectedId(null);

    setSelectedSupportId(id);

    setSelectedPath(null);

    setFileContent(null);

    setFileErr(null);

    setSupportEditing(false);

    setSupportDraft(content);

  }



  async function handleSupportDelete(id: string) {

    if (isSupportRole()) return;

    const doc = supportDocs.find((d) => d.id === id);

    const delName = doc?.storageFileName ?? doc?.objectKey?.split("/").pop();
    if (delName) {

      try {

        await deleteSupportMarkdown(delName);

      } catch {

        /* local o API caída: quitamos de la lista igual */

      }

    }

    removeSupportDoc(id);

    if (selectedSupportId === id) {

      setSelectedSupportId(null);

      setWorkAreaSelectedId(null);

      setFileViewSource("repo");

      setSupportEditing(false);

    }

  }



  function startSupportEdit() {

    const doc = supportDocs.find((d) => d.id === selectedSupportId);

    if (!doc) return;

    setSupportDraft(doc.content);

    setSupportEditing(true);

  }



  function saveSupportEdit() {

    if (!selectedSupportId) return;

    updateSupportDoc(selectedSupportId, supportDraft);

    setSupportEditing(false);

  }



  function cancelSupportEdit() {

    const doc = supportDocs.find((d) => d.id === selectedSupportId);

    setSupportDraft(doc?.content ?? "");

    setSupportEditing(false);

  }



  async function onLogout() {

    setLogoutErr(null);

    setLogoutLoading(true);

    try {

      await logoutSession();

      clearGitConnectRequest();

      navigate("/", { replace: true });

    } catch (e) {

      setLogoutErr(e instanceof Error ? e.message : String(e));

    } finally {

      setLogoutLoading(false);

    }

  }

  async function onChat(e: FormEvent) {

    e.preventDefault();

    if (!ingestComplete) return;

    if (chatLoading) return;

    setChatErr(null);

    const q = question.trim();

    if (!q) return;

    setChatLoading(true);

    const streamId = `stream-${Date.now()}`;

    setChatTurns((prev) => [
      ...prev,
      {
        id: streamId,
        question: q,
        answer: "",
        sources: [],
        repoLabel: "",
        createdAt: new Date().toISOString(),
      },
    ]);

    try {
      let convForChat = baseChatConversationId;
      if (taskContext?.taskId != null && taskContext?.huCode?.trim()) {
        const r = await fetchChatHistory(50, {
          taskId: taskContext.taskId,
          huCode: taskContext.huCode,
          ...(taskContext.cellLabel?.trim() ? { cellName: taskContext.cellLabel.trim() } : {}),
        });
        if (r.resolvedConversationId) {
          setResolvedPrimaryChatId(r.resolvedConversationId);
          convForChat = r.resolvedConversationId;
        }
      }

      await streamVectorChat(
        q,
        {
          onStart: (sources) => {
            setChatTurns((prev) =>
              prev.map((t) => (t.id === streamId ? { ...t, sources } : t)),
            );
          },
          onDelta: (text) => {
            setChatTurns((prev) =>
              prev.map((t) => (t.id === streamId ? { ...t, answer: t.answer + text } : t)),
            );
          },
          onProposals: onWorkAreaChatProposals,
        },
        {
          taskHuCode: taskContext?.huCode,
          ...(taskContext?.taskId != null ? { taskId: taskContext.taskId } : {}),
          ...(convForChat ? { conversationId: convForChat } : {}),
          ...(taskContext?.cellLabel?.trim() ? { cellName: taskContext.cellLabel.trim() } : {}),
        },
      );

      setQuestion("");

      const localTurn = (id: string, answer: string, sources: string[]): ChatHistoryEntry => ({
        id,
        question: q,
        answer,
        sources,
        repoLabel: "",
        createdAt: new Date().toISOString(),
      });

      try {

        const { entries: rows } =
          taskContext?.taskId != null && taskContext?.huCode?.trim()
            ? await fetchChatHistory(50, {
                taskId: taskContext.taskId,
                huCode: taskContext.huCode,
                ...(taskContext.cellLabel?.trim() ? { cellName: taskContext.cellLabel.trim() } : {}),
              })
            : await fetchChatHistory(50, { conversationId: convForChat });

        setChatHistoryErr(null);

        setChatTurns((prev) => {
          const local = prev.find((t) => t.id === streamId);
          return mergeFirestoreHistoryWithLocalStream(rows, local, q);
        });

      } catch (histErr) {

        setChatHistoryErr(histErr instanceof Error ? histErr.message : String(histErr));

        setChatTurns((prev) => {
          const cur = prev.find((t) => t.id === streamId);
          const answer = cur?.answer ?? "";
          const sources = cur?.sources ?? [];
          return [
            ...prev.filter((t) => t.id !== streamId),
            localTurn(`local-${Date.now()}`, answer, sources),
          ];
        });

      }

    } catch (err) {

      setChatErr(err instanceof Error ? err.message : String(err));

      setChatTurns((prev) => prev.filter((t) => t.id !== streamId));

    } finally {

      setChatLoading(false);

    }

  }



  if (!connect?.directory) {

    if (restorePhase === "trying") {

      return (

        <div className="page">

          <p>Restaurando conexión con el repositorio…</p>

        </div>

      );

    }

    if (!loadGitConnectRequest() && !state?.connect) {

      return null;

    }

    return (

      <div className="page">

        <p>

          No hay datos de repositorio.{" "}

          <Link to="/">Volver al inicio</Link>

        </p>

      </div>

    );

  }



  const dir: FolderStructureDto = connect.directory;



  const selectedSupportDoc =

    selectedSupportId != null ? supportPanelDocs.find((d) => d.id === selectedSupportId) : undefined;

  const selectedWorkAreaProposal =

    workAreaSelectedId != null ? workAreaPanelProposals.find((p) => p.id === workAreaSelectedId) : undefined;

  const headerFileLabel =

    fileViewSource === "support" && selectedSupportDoc

      ? selectedSupportDoc.name

      : fileViewSource === "workarea" && selectedWorkAreaProposal

        ? selectedWorkAreaProposal.fileName

        : selectedPath?.trim()

          ? basenameRel(selectedPath)

          : null;

  const headerFileTitle =

    fileViewSource === "support" && selectedSupportDoc

      ? `Soporte · ${selectedSupportDoc.name}`

      : fileViewSource === "workarea" && selectedWorkAreaProposal

        ? selectedWorkAreaProposal.sourcePath

          ? `${selectedWorkAreaProposal.fileName} · ${selectedWorkAreaProposal.sourcePath}`

          : selectedWorkAreaProposal.fileName

        : selectedPath?.trim()

          ? selectedPath

          : undefined;



  return (

    <div className="page page--workspace workspace">

      <div className="workspace__shell">

        <aside

          className={

            "workspace__session-rail" +

            (sessionPanelOpen ? " workspace__session-rail--open" : " workspace__session-rail--collapsed")

          }

          aria-label={isSupportRole() ? "Sesión y soporte" : "Sesión e índice"}

        >

          <div

            className={

              "workspace__session-rail-toolbar" +

              (!sessionPanelOpen ? " workspace__session-rail-toolbar--collapsed" : "")

            }

          >

            <button

              type="button"

              className="workspace__session-rail-toggle"

              onClick={() => setSessionPanelOpen((v) => !v)}

              aria-expanded={sessionPanelOpen}

              title={sessionPanelOpen ? "Ocultar panel lateral" : "Mostrar panel lateral"}

            >

              {sessionPanelOpen ? (

                <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" aria-hidden>

                  <path

                    d="M9 5H6.5A1.5 1.5 0 0 0 5 6.5v11A1.5 1.5 0 0 0 6.5 19H9"

                    stroke="currentColor"

                    strokeWidth="1.75"

                    strokeLinecap="round"

                  />

                  <path

                    d="M14 10l-3 2 3 2M11 12h8"

                    stroke="currentColor"

                    strokeWidth="1.75"

                    strokeLinecap="round"

                    strokeLinejoin="round"

                  />

                </svg>

              ) : (

                <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" aria-hidden>

                  <path

                    d="M9 5H6.5A1.5 1.5 0 0 0 5 6.5v11A1.5 1.5 0 0 0 6.5 19H9"

                    stroke="currentColor"

                    strokeWidth="1.75"

                    strokeLinecap="round"

                  />

                  <path

                    d="M13 10l3 2-3 2M16 12H8"

                    stroke="currentColor"

                    strokeWidth="1.75"

                    strokeLinecap="round"

                    strokeLinejoin="round"

                  />

                </svg>

              )}

            </button>

          </div>

          {sessionPanelOpen && (

            <div className="workspace__session-rail-body">

              <div className="workspace__session-rail-user session-rail-panel__identity">
                <span className="workspace__header-user">
                  {(getUserId().trim() || connect.usuario).toUpperCase()}
                </span>
                <span className="workspace__header-session-hint muted session-rail-panel__role">
                  {workspaceRoleLabel().toUpperCase()}
                </span>
                <p className="workspace__session-rail-hint muted small">
                  Tras F5 o reinicio del backend, usa «Reconectar» junto a Consulta (se guarda la última URL en esta
                  pestaña) o vuelve al inicio.
                </p>
              </div>

              {taskContext && (
                <div className="workspace__task-brief">
                  <button
                    type="button"
                    className="btn btn--small workspace__task-brief__back"
                    onClick={() => navigate(taskContext.returnPath)}
                  >
                    ← Volver a células
                  </button>
                  {taskContext.cellLabel && (
                    <p className="workspace__task-brief__cell muted small">{taskContext.cellLabel}</p>
                  )}
                  <p className="workspace__task-brief__hu small">
                    <strong>{taskContext.huCode}</strong>
                  </p>
                  <p className="workspace__task-brief__enunciado muted small">{taskContext.enunciado}</p>
                </div>
              )}

              {!isSupportRole() && headerFileLabel && (
                <p className="workspace__session-rail-file muted small" title={headerFileTitle ?? undefined}>
                  {headerFileLabel}
                </p>
              )}

              {!isSupportRole() && (
              <div className="workspace__bar-ingest workspace__bar-ingest--rail" aria-live="polite">

          {ingestErr && (

            <p className="error small workspace__bar-ingest-err" role="alert">

              {ingestErr}

            </p>

          )}

          {ingestLoading && ingestProgress && (

            <div className="ingest-progress ingest-progress--bar">

              <p className="ingest-progress__lead ingest-progress__lead--bar small muted">

                Indexando → pgvector…

              </p>

              <div className="ingest-progress__stats ingest-progress__stats--bar">

                {ingestProgress.mode === "sync" ? (

                  <span className="muted">Servidor indexando (sin avance intermedio)…</span>

                ) : ingestProgress.totalFiles > 0 ? (

                  <>

                    Archivos:{" "}

                    <strong>

                      {ingestProgress.filesProcessed} / {ingestProgress.totalFiles}

                    </strong>

                    <span className="muted"> · Chunks: {ingestProgress.chunksIndexed}</span>

                  </>

                ) : (

                  <span className="muted">Preparando lista…</span>

                )}

              </div>

              {ingestProgress.detail && (

                <div className="ingest-progress__detail ingest-progress__detail--bar small muted">

                  {ingestProgress.detail}

                </div>

              )}

              {ingestProgress.currentFile && (

                <div

                  className="ingest-progress__file ingest-progress__file--bar small muted"

                  title={ingestProgress.currentFile}

                >

                  {ingestProgress.currentFile}

                </div>

              )}

              <div

                className={

                  "ingest-progress__track ingest-progress__track--bar" +

                  (ingestProgress.mode === "sync" || ingestProgress.totalFiles === 0

                    ? " ingest-progress__track--indeterminate"

                    : "")

                }

              >

                <div

                  className="ingest-progress__fill"

                  style={{

                    width:

                      ingestProgress.totalFiles > 0

                        ? `${Math.min(100, (ingestProgress.filesProcessed / ingestProgress.totalFiles) * 100)}%`

                        : "30%",

                  }}

                />

              </div>

            </div>

          )}

          {ingestComplete && ingestResult && (

            <div className="ingest-complete ingest-complete--bar" role="status">

              <div className="ingest-complete__head">

                <span className="ingest-complete__title">Índice listo</span>

                <span className="ingest-complete__stats ingest-complete__stats--bar ingest-complete__stats--below-title small">

                  <strong>{ingestResult.filesProcessed}</strong> arch ·{" "}

                  <strong>{ingestResult.chunksIndexed}</strong> chunks ·{" "}

                  <code className="ingest-complete__ns">{ingestResult.namespace}</code>

                </span>

              </div>

              {ingestResult.skipped.length > 0 && (

                <div

                  className="ingest-skipped-details ingest-skipped-details--bar ingest-skipped-details--panel small"

                  role="region"

                  aria-label="Archivos omitidos de la indexación"

                >

                  <button

                    type="button"

                    className="ingest-skipped-details__toggle"

                    onClick={() => setOmitidosOpen((v) => !v)}

                    aria-expanded={omitidosOpen}

                  >

                    <span className="ingest-skipped-details__caret" aria-hidden>

                      {omitidosOpen ? "▼" : "▶"}

                    </span>

                    Omitidos ({ingestResult.skipped.length})

                  </button>

                  {omitidosOpen && (

                    <div className="ingest-skipped-list-wrap">

                      <ul className="ingest-skipped-list">

                        {ingestResult.skipped.map((s, i) => (

                          <li key={`${i}-${s}`}>{s}</li>

                        ))}

                      </ul>

                    </div>

                  )}

                </div>

              )}

            </div>

          )}

        </div>
              )}

              {isSupportRole() && (
                <div className="workspace__support-in-session-rail">
                  <h2 className="workspace__support-rail-title">SOPORTE</h2>
                  <div className="workspace__support-wrap">
                    <SupportPanel
                      documents={supportPanelDocs}
                      selectedId={selectedSupportId}
                      onSelect={onSelectSupport}
                      onUpload={handleSupportUpload}
                      onDelete={handleSupportDelete}
                      uploadUi={supportUploadUi}
                      readOnly
                    />
                  </div>
                </div>
              )}

            </div>

          )}

          {sessionPanelOpen && (

            <footer className="workspace__session-rail-footer">

              {logoutErr && (

                <p className="error small workspace__session-rail-footer-err" role="alert">

                  {logoutErr}

                </p>

              )}

              <button

                type="button"

                className="workspace__session-rail-logout-link"

                onClick={onLogout}

                disabled={logoutLoading}

                aria-busy={logoutLoading}

              >

                {logoutLoading ? "Cerrando…" : "CERRAR SESION"}

              </button>

            </footer>

          )}

        </aside>



        <div className="workspace__main">

      <div className="workspace__main-grid-wrap">

      <div
        ref={gridRef}
        className={"workspace__grid" + (isResizable ? " workspace__grid--resizable" : "")}
        style={
          isResizable
            ? {
                display: "grid",
                gridTemplateColumns: `${cols[0]}% ${WORKSPACE_RESIZE_HANDLE_PX}px ${cols[1]}% ${WORKSPACE_RESIZE_HANDLE_PX}px ${cols[2]}%`,
                gap: 0,
                alignItems: "stretch",
              }
            : undefined
        }
      >

        <aside className="panel workspace__panel workspace__panel--sidebar">

          <div className="workspace__sidebar-split">
            <div className="workspace__sidebar-section workspace__sidebar-section--tree">
              <h2>CONTEXTO MAESTRO</h2>

              <div className="workspace__sidebar-tree-scroll">
                <FolderTree root={dir} onSelectFile={onSelectFile} selectedPath={selectedPath} />
              </div>
            </div>

            <div className="workspace__sidebar-section workspace__sidebar-section--work">
              <WorkAreaPanel
                proposals={workAreaPanelProposals}
                selectedId={fileViewSource === "workarea" ? workAreaSelectedId : null}
                onSelect={onSelectWorkAreaChip}
                onAcceptAll={() => void handleWorkAreaAcceptAll()}
                notice={workAreaNotice}
                error={workAreaErr}
                busy={workAreaKeepLoadingId !== null}
                downloadRequestInit={workAreaTaskHeaders}
                persistenceHint={workAreaPersistenceHint}
                onDeleteS3Artifact={(p) => void handleWorkAreaDeleteS3Artifact(p)}
              />
            </div>
          </div>

        </aside>

        {isResizable && (
          <div
            className="workspace__col-resize"
            role="separator"
            aria-orientation="vertical"
            aria-label="Redimensionar columnas contexto y archivo"
            title="Arrastrar para cambiar el ancho · doble clic: restablecer"
            onMouseDown={onMouseDownLeft}
            onDoubleClick={(e) => {
              e.preventDefault();
              resetWidths();
            }}
          />
        )}

        <section className="panel workspace__panel workspace__panel--file">

          <h2>
            {fileViewSource === "support"
              ? "Soporte"
              : fileViewSource === "workarea"
                ? "Área de trabajo"
                : "Archivo"}
          </h2>

          {fileViewSource === "repo" && selectedPath && <div className="path">{selectedPath}</div>}

          {fileViewSource === "workarea" && selectedWorkAreaProposal && (
            <div className="path">
              {selectedWorkAreaProposal.fileName}
              {selectedWorkAreaProposal.artifactViewOnly && selectedWorkAreaProposal.s3Bucket && (
                <>
                  {" "}
                  <span className="muted">· S3:</span>{" "}
                  <code className="work-area-panel__code">{selectedWorkAreaProposal.s3Bucket}</code>
                </>
              )}
              {!selectedWorkAreaProposal.artifactViewOnly && selectedWorkAreaProposal.draftRelativePath && (
                <>
                  {" "}
                  <span className="muted">· Borrador:</span>{" "}
                  <code className="work-area-panel__code">{selectedWorkAreaProposal.draftRelativePath}</code>
                </>
              )}
              {!selectedWorkAreaProposal.artifactViewOnly &&
                selectedWorkAreaProposal.acceptedRelativePath &&
                !selectedWorkAreaProposal.draftRelativePath && (
                  <>
                    {" "}
                    <span className="muted">· Generado:</span>{" "}
                    <code className="work-area-panel__code">{selectedWorkAreaProposal.acceptedRelativePath}</code>
                  </>
                )}
              {!selectedWorkAreaProposal.artifactViewOnly && selectedWorkAreaProposal.sourcePath && (
                <>
                  {" "}
                  <span className="muted">· Basado en:</span>{" "}
                  <code className="work-area-panel__code">{selectedWorkAreaProposal.sourcePath}</code>
                </>
              )}
            </div>
          )}

          {fileViewSource === "support" && selectedSupportDoc && (

            <div className="path">

              Soporte · {selectedSupportDoc.name}

              {!isSupportRole() && (
                <span className="muted small workspace__path-hint">(local — copia en este navegador)</span>
              )}
              {isSupportRole() && (
                <span className="muted small workspace__path-hint">(solo lectura — S3)</span>
              )}

            </div>

          )}



          <div className="workspace__file-body">

            {fileViewSource === "workarea" && selectedWorkAreaProposal && (
              <>
                {selectedWorkAreaProposal.artifactViewOnly &&
                  selectedWorkAreaProposal.s3Bucket &&
                  selectedWorkAreaProposal.s3ObjectKey && (
                    <div className="workspace__file-toolbar workspace__file-toolbar--work-area workspace__file-toolbar--s3-artifact">
                      <button
                        type="button"
                        className="work-area-panel__icon-btn"
                        disabled={workAreaKeepLoadingId !== null}
                        title="Descargar"
                        aria-label={`Descargar ${selectedWorkAreaProposal.fileName}`}
                        onClick={() => void handleWorkAreaToolbarDownloadS3()}
                      >
                        <WorkAreaIconDownload />
                      </button>
                      <button
                        type="button"
                        className="work-area-panel__icon-btn work-area-panel__icon-btn--danger"
                        disabled={workAreaKeepLoadingId !== null}
                        title="Eliminar de S3"
                        aria-label={`Eliminar ${selectedWorkAreaProposal.fileName} de S3`}
                        onClick={() => void handleWorkAreaDeleteS3Artifact(selectedWorkAreaProposal)}
                      >
                        <WorkAreaIconTrash />
                      </button>
                      {isEditableS3Artifact(selectedWorkAreaProposal) ? (
                        !workAreaS3Editing ? (
                          <button
                            type="button"
                            className="btn"
                            disabled={workAreaKeepLoadingId !== null}
                            onClick={startWorkAreaS3Edit}
                          >
                            Editar
                          </button>
                        ) : (
                          <>
                            <button
                              type="button"
                              className="btn primary"
                              disabled={workAreaKeepLoadingId !== null}
                              onClick={() => void saveWorkAreaS3Edit()}
                            >
                              {workAreaKeepLoadingId === selectedWorkAreaProposal.id
                                ? "Guardando…"
                                : isWorkareaS3Artifact(selectedWorkAreaProposal)
                                  ? "Guardar y reindexar"
                                  : "Guardar borrador en S3"}
                            </button>
                            <button type="button" className="btn" onClick={cancelWorkAreaS3Edit}>
                              Cancelar
                            </button>
                          </>
                        )
                      ) : null}
                    </div>
                  )}
                {!selectedWorkAreaProposal.artifactViewOnly && (
                <div className="workspace__file-toolbar workspace__file-toolbar--work-area">
                  {selectedWorkAreaProposal.draftRelativePath && (
                    <>
                      {workAreaCloneDraftEditing ? (
                        <button type="button" className="btn" onClick={cancelWorkAreaCloneDraftEdit}>
                          Cancelar edición
                        </button>
                      ) : (
                        <button
                          type="button"
                          className="btn"
                          disabled={workAreaKeepLoadingId !== null}
                          onClick={startWorkAreaCloneDraftEdit}
                        >
                          Editar texto
                        </button>
                      )}
                      <button
                        type="button"
                        className="btn primary"
                        disabled={workAreaKeepLoadingId !== null}
                        aria-busy={workAreaKeepLoadingId === selectedWorkAreaProposal.id}
                        onClick={() => void handleWorkAreaSaveFinalize(selectedWorkAreaProposal.id)}
                      >
                        {workAreaKeepLoadingId === selectedWorkAreaProposal.id
                          ? "Guardando…"
                          : "Guardar en workarea"}
                      </button>
                      <button
                        type="button"
                        className="btn"
                        disabled={workAreaKeepLoadingId !== null}
                        title="Usa el archivo .txt del clon tal cual está en disco (ignora resolución en pantalla)."
                        onClick={() => void handleWorkAreaAccept(selectedWorkAreaProposal.id)}
                      >
                        {workAreaKeepLoadingId === selectedWorkAreaProposal.id ? "Aplicando…" : "Desde disco"}
                      </button>
                    </>
                  )}
                  {!selectedWorkAreaProposal.draftRelativePath &&
                    selectedWorkAreaProposal.draftVersion != null &&
                    selectedWorkAreaProposal.sourcePath &&
                    (selectedWorkAreaProposal.content?.trim().length ?? 0) > 0 && (
                      <button
                        type="button"
                        className="btn primary"
                        disabled={workAreaKeepLoadingId !== null}
                        aria-busy={workAreaKeepLoadingId === selectedWorkAreaProposal.id}
                        onClick={() => void handleWorkAreaApplyMergeFinal(selectedWorkAreaProposal.id)}
                      >
                        {workAreaKeepLoadingId === selectedWorkAreaProposal.id ? "Aplicando…" : "Aceptar"}
                      </button>
                    )}
                  {selectedWorkAreaProposal.acceptedRelativePath && !selectedWorkAreaProposal.draftRelativePath && (
                    <button
                      type="button"
                      className="btn primary"
                      disabled={workAreaKeepLoadingId !== null}
                      aria-busy={workAreaKeepLoadingId === selectedWorkAreaProposal.id}
                      onClick={() => void handleWorkAreaIndexDraft(selectedWorkAreaProposal.id)}
                    >
                      {workAreaKeepLoadingId === selectedWorkAreaProposal.id
                        ? "Indexando…"
                        : selectedWorkAreaProposal.vectorIndexed
                          ? "Volver a indexar"
                          : "Indexar borrador"}
                    </button>
                  )}
                  <button
                    type="button"
                    className="btn"
                    disabled={workAreaKeepLoadingId !== null}
                    onClick={() => void handleWorkAreaDismiss(selectedWorkAreaProposal.id)}
                  >
                    Descartar
                  </button>
                </div>
                )}
                {!selectedWorkAreaProposal.artifactViewOnly &&
                  selectedWorkAreaProposal.acceptedRelativePath &&
                  !selectedWorkAreaProposal.draftRelativePath && (
                  <div className="workspace__workarea-accepted-note muted small" role="status">
                    {selectedWorkAreaProposal.vectorIndexed ? (
                      <>
                        Incluido en el índice vectorial (RAG)
                        {selectedWorkAreaProposal.lastIndexedChunks != null
                          ? ` — ${selectedWorkAreaProposal.lastIndexedChunks} fragmentos en la última indexación.`
                          : "."}{" "}
                        Puedes «Volver a indexar» si cambias el archivo en el clon.
                      </>
                    ) : (
                      <>
                        El archivo ya está en el clon sin <code>.txt</code>. Pruébalo; cuando quieras incluirlo en el RAG,
                        usa «Indexar borrador».
                      </>
                    )}
                  </div>
                )}
                <div className="workspace__workarea-viewer">
                {(() => {
                  const p = selectedWorkAreaProposal;
                  if (workAreaPreviewLoadingId === p.id) {
                    return (
                      <div className="workspace__file-placeholder muted small" role="status">
                        {p.artifactViewOnly ? "Cargando archivo desde S3…" : "Cargando borrador desde el servidor…"}
                      </div>
                    );
                  }
                  if (workAreaS3Editing && isEditableS3Artifact(p)) {
                    return (
                      <textarea
                        className="workspace__workarea-s3-editor"
                        value={workAreaS3EditDraft}
                        onChange={(e) => setWorkAreaS3EditDraft(e.target.value)}
                        spellCheck={false}
                        aria-label={`Editar borrador ${p.fileName}`}
                      />
                    );
                  }
                  if (workAreaCloneDraftEditing && p.draftRelativePath && !p.artifactViewOnly) {
                    return (
                      <textarea
                        className="workspace__workarea-s3-editor"
                        value={workAreaCloneDraftBuffer}
                        onChange={(e) => setWorkAreaCloneDraftBuffer(e.target.value)}
                        spellCheck={false}
                        aria-label={`Editar borrador ${p.fileName}`}
                      />
                    );
                  }
                  // DocViz: vista tipo VS Code (bloques + barra). Git estándar: ConflictInlineCodeViewer.
                  if (p.content && p.content.trim().length > 0) {
                    if (hasDocvizMergeMarkers(p.content)) {
                      return (
                        <WorkAreaConflictViewer text={p.content} onResolvedChange={onWorkAreaDocvizResolved} />
                      );
                    }
                    if (hasGitConflictMarkers(p.content)) {
                      return (
                        <ConflictInlineCodeViewer
                          ref={workAreaConflictViewerRef}
                          fileContent={p.content}
                          fileName={p.fileName}
                          className="file-preview"
                        />
                      );
                    }
                    return <FilePreviewWithLineNumbers text={p.content} />;
                  }
                  if (p.draftRelativePath) {
                    return <FilePreviewWithLineNumbers text={p.content ?? ""} />;
                  }
                  if (p.acceptedRelativePath && !p.draftRelativePath) {
                    return null;
                  }
                  return (
                    <FilePreviewWithLineNumbers
                      text={workAreaProposalFallbackPayloadText(p)}
                      className="work-area-proposal-raw"
                    />
                  );
                })()}
                </div>
              </>
            )}

            {fileViewSource === "workarea" && !selectedWorkAreaProposal && workAreaPanelProposals.length > 0 && (
              <div className="workspace__file-placeholder muted small">
                Elige un archivo en la lista del área de trabajo (columna izquierda).
              </div>
            )}

            {fileViewSource === "repo" && fileErr && <p className="error">{fileErr}</p>}

            {fileViewSource === "repo" && fileContent !== null && (
              hasGitConflictMarkers(fileContent) ? (
                <ConflictInlineCodeViewer
                  fileContent={fileContent}
                  fileName={selectedPath?.split("/").pop() ?? undefined}
                  className="file-preview"
                />
              ) : (
                <FilePreviewWithLineNumbers text={fileContent} />
              )
            )}

            {fileViewSource === "repo" && selectedPath && fileContent === null && !fileErr && (

              <div className="workspace__file-placeholder muted small">Cargando archivo…</div>

            )}

            {fileViewSource === "repo" && !selectedPath && (

              <div className="workspace__file-placeholder muted small">

                Elige un archivo del contexto maestro.

              </div>

            )}

            {fileViewSource === "support" && selectedSupportDoc && (

              <>

                <div className="workspace__file-toolbar">

                  {!isSupportRole() && (
                    <>
                      {!supportEditing ? (
                        <button type="button" className="btn" onClick={startSupportEdit}>
                          Editar Markdown
                        </button>
                      ) : (
                        <>
                          <button type="button" className="btn primary" onClick={saveSupportEdit}>
                            Guardar
                          </button>
                          <button type="button" className="btn" onClick={cancelSupportEdit}>
                            Cancelar
                          </button>
                        </>
                      )}
                    </>
                  )}

                </div>

                {supportEditing ? (

                  <textarea

                    className="workspace__support-editor"

                    value={supportDraft}

                    onChange={(e) => setSupportDraft(e.target.value)}

                    spellCheck={false}

                    aria-label="Contenido Markdown"

                  />

                ) : (

                  <div className="workspace__support-preview">

                    <ChatMarkdown content={selectedSupportDoc.content} />

                  </div>

                )}

              </>

            )}

            {fileViewSource === "support" && !selectedSupportDoc && (

              <div className="workspace__file-placeholder muted small">

                {isSupportRole()
                  ? "Elige un documento de soporte en el panel lateral (SOPORTE)."
                  : "Sube un .md o elige un soporte en el panel SOPORTE (barra derecha)."}

              </div>

            )}

          </div>

        </section>

        {isResizable && (
          <div
            className="workspace__col-resize"
            role="separator"
            aria-orientation="vertical"
            aria-label="Redimensionar columnas archivo y consulta"
            title="Arrastrar para cambiar el ancho · doble clic: restablecer"
            onMouseDown={onMouseDownRight}
            onDoubleClick={(e) => {
              e.preventDefault();
              resetWidths();
            }}
          />
        )}

        <aside className="panel workspace__panel workspace__panel--chat">

          <div className="workspace__panel-chat-head">

            <h2 className="workspace__panel-chat-title">Consulta</h2>

            <button

              type="button"

              className="btn btn--small workspace__panel-chat-reconnect"

              onClick={() => void reconnectFromSaved()}

              disabled={reconnectLoading || ingestLoading}

              title="Vuelve a registrar el clon Git en el servidor (útil tras F5 o reinicio del backend). Usa la última URL guardada en esta pestaña."

            >

              {reconnectLoading ? "Reconectando…" : "Reconectar"}

            </button>

          </div>

          {isRepoSessionLostError(chatErr) && (

            <p className="workspace__chat-session-lost small" role="status">

              La sesión del servidor con el repositorio se perdió; el árbol puede seguir mostrándose desde la copia en

              pantalla. Pulsa <strong>Reconectar</strong> o vuelve a indexar tras reconectar.

            </p>

          )}

          <div className="workspace__chat-scroll">

          {chatHistoryErr && (

            <p className="error small workspace__chat-scroll-err" role="status">

              Historial: {chatHistoryErr}

            </p>

          )}

          {chatErr && <p className="error workspace__chat-scroll-err">{chatErr}</p>}

          <div className="chat-thread">

            {chatTurns.map((t, turnIdx) => {
              const { entradaUsuario, promptFinal } = splitRagChatQuestion(t.question);
              return (
              <article
                key={t.id}
                className={
                  "chat-thread__turn" +
                  (chatLoading && turnIdx === chatTurns.length - 1 ? " chat-thread__turn--streaming" : "")
                }
                aria-busy={chatLoading && turnIdx === chatTurns.length - 1}
              >

                <div className="chat-thread__question">

                  <span className="chat-thread__label">Tu mensaje</span>

                  <div className="chat-thread__question-user">{entradaUsuario}</div>

                  {promptFinal ? (
                    <details className="chat-thread__thinking">
                      <summary className="chat-thread__thinking-summary">Pensando · instrucciones al modelo</summary>
                      <pre className="chat-thread__thinking-pre">{promptFinal}</pre>
                    </details>
                  ) : null}

                </div>

                <div
                  className={
                    "chat-thread__answer" +
                    (chatLoading && turnIdx === chatTurns.length - 1 ? " chat-thread__answer--streaming" : "")
                  }
                >

                  <span className="chat-thread__label">Asistente</span>

                  {t.answer || !chatLoading ? (
                    <ChatMarkdown content={formatChatAnswerForDisplay(t.answer)} />
                  ) : (
                    <p className="muted small chat-thread__generating">Generando…</p>
                  )}

                  {t.sources && t.sources.length > 0 && (

                    <div className="chat-answer__sources">

                      <span className="chat-answer__sources-label">Fuentes</span>

                      <ul className="chat-answer__sources-list">

                        {t.sources.map((s, i) => (

                          <li key={`${t.id}-s-${i}-${s}`}>{s}</li>

                        ))}

                      </ul>

                    </div>

                  )}

                </div>

              </article>

            );})}

          </div>

          </div>

          <form ref={chatFormRef} className="chat-form workspace__chat-composer" onSubmit={onChat}>

            <label className="field workspace__question-field">

              <span>Pregunta (RAG)</span>

              <div className="workspace__question-wrap">
                <textarea

                  rows={3}

                  className="workspace__question-textarea"

                  value={question}

                  onChange={(e) => setQuestion(e.target.value)}

                  onKeyDown={onQuestionKeyDown}

                  onDragOver={onQuestionDragOver}

                  onDrop={onQuestionDrop}

                  disabled={!ingestComplete}

                  title="Enter envía · Mayús+Enter nueva línea. Arrastra: @[repo:…] · @[soporte:…]"

                  placeholder={

                    ingestComplete

                      ? "Pregunta… Arrastra archivos: repo → @[repo:…] · soporte → @[soporte:…]"

                      : ingestLoading

                        ? "Espera a que termine la indexación…"

                        : "Espera a que el índice esté listo…"

                  }

                />

                <div
                  className="workspace__question-toolbar"
                  role="toolbar"
                  aria-label="Enviar pregunta"
                  aria-busy={chatLoading}
                >
                  {chatLoading ? (
                    <span className="workspace__question-toolbar-status" role="status">
                      Generando respuesta…
                    </span>
                  ) : (
                    <span className="workspace__question-toolbar-spacer" aria-hidden />
                  )}
                  <button
                    type="submit"
                    className="workspace__question-send"
                    disabled={!ingestComplete || chatLoading}
                    aria-label={chatLoading ? "Generando respuesta" : "Enviar pregunta"}
                  >
                    {chatLoading ? (
                      <span className="workspace__question-send-spinner" aria-hidden />
                    ) : (
                      <svg
                        className="workspace__question-send-icon"
                        width="18"
                        height="18"
                        viewBox="0 0 24 24"
                        fill="none"
                        xmlns="http://www.w3.org/2000/svg"
                        aria-hidden
                      >
                        <path
                          d="M12 5v14M5 12l7-7 7 7"
                          stroke="currentColor"
                          strokeWidth="2"
                          strokeLinecap="round"
                          strokeLinejoin="round"
                        />
                      </svg>
                    )}
                  </button>
                </div>
              </div>

            </label>

          </form>

        </aside>

      </div>

      </div>

      {!isSupportRole() && (
      <aside

        className={

          "workspace__support-rail" +

          (supportRailOpen ? " workspace__support-rail--open" : " workspace__support-rail--collapsed")

        }

        aria-label="Documentos de soporte"

      >

        <div

          className={

            "workspace__support-rail-toolbar" +

            (!supportRailOpen ? " workspace__support-rail-toolbar--collapsed" : "")

          }

        >

          <button

            type="button"

            className="workspace__support-rail-toggle"

            onClick={() => setSupportRailOpen((v) => !v)}

            aria-expanded={supportRailOpen}

            title={supportRailOpen ? "Ocultar panel de soporte" : "Mostrar panel de soporte"}

          >

            {supportRailOpen ? (

              <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" aria-hidden>

                <path

                  d="M15 5h2.5A1.5 1.5 0 0 1 19 6.5v11a1.5 1.5 0 0 1-1.5 1.5H15"

                  stroke="currentColor"

                  strokeWidth="1.75"

                  strokeLinecap="round"

                />

                <path

                  d="M10 10l3 2-3 2M13 12H5"

                  stroke="currentColor"

                  strokeWidth="1.75"

                  strokeLinecap="round"

                  strokeLinejoin="round"

                />

              </svg>

            ) : (

              <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" aria-hidden>

                <path

                  d="M15 5h2.5A1.5 1.5 0 0 1 19 6.5v11a1.5 1.5 0 0 1-1.5 1.5H15"

                  stroke="currentColor"

                  strokeWidth="1.75"

                  strokeLinecap="round"

                />

                <path

                  d="M11 10l-3 2 3 2M8 12h8"

                  stroke="currentColor"

                  strokeWidth="1.75"

                  strokeLinecap="round"

                  strokeLinejoin="round"

                />

              </svg>

            )}

          </button>

        </div>

        {supportRailOpen && (

          <div className="workspace__support-rail-body">

            <h2 className="workspace__support-rail-title">SOPORTE</h2>

            <div className="workspace__support-wrap">

              <SupportPanel

                documents={supportPanelDocs}

                selectedId={selectedSupportId}

                onSelect={onSelectSupport}

                onUpload={handleSupportUpload}

                onDelete={handleSupportDelete}

                uploadUi={supportUploadUi}

                readOnly={isSupportRole()}

              />

            </div>

          </div>

        )}

      </aside>
      )}

        </div>

      </div>

    </div>

  );

}

