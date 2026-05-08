import { FormEvent, useCallback, useEffect, useMemo, useState } from "react";
import type { CellRepoRequestBody } from "../types";
import { useMatch, useNavigate, useParams } from "react-router-dom";
import { FolderTree } from "../components/FolderTree";
import { ChatMarkdown } from "../components/ChatMarkdown";
import {
  adminAssignReposToCell,
  adminCreateCell,
  adminDeleteCellSupportMarkdown,
  adminDeletePendingRepo,
  adminDeletePendingSupportMarkdown,
  adminDeleteRepo,
  adminFetchPendingRepoFile,
  adminFetchRepoDeleteImpact,
  adminFetchPendingRepoTree,
  adminFetchRepoFile,
  adminFetchRepoTree,
  adminIndexRepoStream,
  adminRepoUrlHint,
  adminUpdateCell,
  adminUpdateCellSupportMarkdown,
  adminUpdatePendingSupportMarkdown,
  adminUploadCellSupportMarkdown,
  adminUploadPendingSupportMarkdown,
  fetchCellRepos,
  fetchCells,
  fetchTextFromPresignedUrl,
  getUserId,
  isSupportRole,
  listSupportMarkdownObjects,
  newVectorNamespaceFromRepoName,
  parseGitRepoNameFromHttpsUrl,
} from "../api/client";
import { randomUuid } from "../util/randomUuid";
import type {
  CellRepoResponse,
  CellResponse,
  FolderStructureDto,
  GitConnectionMode,
  IngestProgressEvent,
  SupportMarkdownObjectDto,
} from "../types";

type PendingIndexed = {
  clientId: string;
  repo: CellRepoResponse;
};

function newId(): string {
  return randomUuid();
}

type IngestProgressState = {
  totalFiles: number;
  filesProcessed: number;
  chunksIndexed: number;
  currentFile: string | null;
  detail: string | null;
  /** Resumen de rutas omitidas o errores por archivo (NDJSON DONE / CELL_REPO_READY). */
  skippedHint: string | null;
};

function summarizeSkippedPaths(skipped: string[] | undefined | null): string | null {
  if (skipped == null || skipped.length === 0) return null;
  const max = 2;
  const head = skipped.slice(0, max).join("; ");
  return skipped.length > max ? `${head} (+${skipped.length - max} más)` : head;
}

function mergeIngestProgress(
  prev: IngestProgressState | null,
  ev: IngestProgressEvent,
): IngestProgressState {
  if (ev.phase === "START" && ev.totalFiles != null) {
    return {
      totalFiles: ev.totalFiles,
      filesProcessed: 0,
      chunksIndexed: 0,
      currentFile: null,
      detail:
        ev.totalFiles === 0
          ? "Sin archivos de texto para indexar en esta revisión (solo binarios u omitidos por tipo)."
          : null,
      skippedHint: null,
    };
  }
  if (ev.phase === "FILE" || ev.phase === "PROGRESS") {
    return {
      totalFiles: ev.totalFiles ?? prev?.totalFiles ?? 0,
      filesProcessed: ev.filesProcessed ?? prev?.filesProcessed ?? 0,
      chunksIndexed: ev.chunksIndexed ?? prev?.chunksIndexed ?? 0,
      currentFile: ev.currentFile ?? prev?.currentFile ?? null,
      detail: ev.detail ?? prev?.detail ?? null,
      skippedHint: prev?.skippedHint ?? null,
    };
  }
  if (ev.phase === "DONE") {
    return {
      totalFiles: ev.totalFiles ?? prev?.totalFiles ?? 0,
      filesProcessed: ev.filesProcessed ?? prev?.filesProcessed ?? 0,
      chunksIndexed: ev.chunksIndexed ?? prev?.chunksIndexed ?? 0,
      currentFile: ev.currentFile ?? prev?.currentFile ?? null,
      detail: ev.detail ?? prev?.detail ?? null,
      skippedHint: summarizeSkippedPaths(ev.skipped) ?? prev?.skippedHint ?? null,
    };
  }
  if (ev.phase === "CELL_REPO_READY") {
    const evF = ev.filesProcessed;
    const evC = ev.chunksIndexed;
    const prevF = prev?.filesProcessed ?? 0;
    const prevC = prev?.chunksIndexed ?? 0;
    const filesProcessed =
      evF != null && evF > 0 ? evF : prevF > 0 ? prevF : evF ?? prev?.filesProcessed ?? 0;
    const chunksIndexed =
      evC != null && evC > 0 ? evC : prevC > 0 ? prevC : evC ?? prev?.chunksIndexed ?? 0;
    return {
      totalFiles: prev?.totalFiles ?? ev.totalFiles ?? 0,
      filesProcessed,
      chunksIndexed,
      currentFile: null,
      detail: ev.linkedWithoutReindex ? "Enlazado sin reindexar." : "Indexación completada.",
      skippedHint: summarizeSkippedPaths(ev.skipped) ?? prev?.skippedHint ?? null,
    };
  }
  return (
    prev ?? {
      totalFiles: 0,
      filesProcessed: 0,
      chunksIndexed: 0,
      currentFile: null,
      detail: null,
      skippedHint: null,
    }
  );
}

function toRepoBodyFromForm(p: {
  mode: GitConnectionMode;
  repositoryUrl: string;
  localPath: string;
  displayName: string;
  vectorNamespace: string;
  tagsCsv: string;
  gitUsername: string;
  credentialPlain: string;
}): CellRepoRequestBody {
  if (p.mode === "LOCAL") {
    const lp = p.localPath.trim();
    return {
      repositoryUrl: `local:${lp}`,
      connectionMode: "LOCAL",
      localPath: lp || undefined,
      displayName: p.displayName,
      tagsCsv: p.tagsCsv.trim() || undefined,
      vectorNamespace: p.vectorNamespace,
    };
  }
  return {
    repositoryUrl: p.repositoryUrl.trim(),
    connectionMode: p.mode,
    gitUsername: p.gitUsername.trim() || undefined,
    credentialPlain: p.credentialPlain || undefined,
    displayName: p.displayName,
    tagsCsv: p.tagsCsv.trim() || undefined,
    vectorNamespace: p.vectorNamespace,
  };
}

function mergedRepos(
  isNew: boolean,
  existingRepos: CellRepoResponse[],
  pendingIndexed: PendingIndexed[],
): CellRepoResponse[] {
  const m = new Map<number, CellRepoResponse>();
  if (!isNew) {
    for (const r of existingRepos) m.set(r.id, r);
  }
  for (const p of pendingIndexed) m.set(p.repo.id, p.repo);
  return [...m.values()];
}

/** Mensajes rotativos durante POST multipart de soporte (misma idea que indexación de repo). */
const SUPPORT_UPLOAD_PHASES = [
  "Subiendo el archivo al almacenamiento de objetos…",
  "Extrayendo texto indexable del Markdown…",
  "Generando embeddings y particionando en chunks…",
  "Escribiendo vectores en el namespace del repositorio…",
];

function SupportUploadGearIcon() {
  return (
    <svg
      className="admin-support-upload-progress__gear-svg"
      width="18"
      height="18"
      viewBox="0 0 24 24"
      aria-hidden
    >
      <path
        fill="currentColor"
        d="M19.14 12.94c.04-.31.06-.63.06-.94 0-.31-.02-.63-.06-.94l2.03-1.58c.18-.14.23-.41.12-.61l-1.92-3.32c-.12-.22-.37-.29-.59-.22l-2.39.96c-.5-.38-1.03-.7-1.62-.94l-.36-2.54c-.04-.24-.24-.41-.48-.41h-3.84c-.24 0-.43.17-.47.41l-.36 2.54c-.59.24-1.13.57-1.62.94l-2.39-.96c-.22-.08-.47 0-.59.22L2.74 8.87c-.12.21-.08.47.12.61l2.03 1.58c-.04.31-.07.63-.07.94s.02.63.06.93l-2.03 1.58c-.18.14-.23.41-.12.61l1.92 3.32c.12.22.37.29.59.22l2.39-.96c.5.38 1.03.7 1.62.94l.36 2.54c.05.24.24.41.48.41h3.84c.24 0 .44-.17.48-.41l.36-2.54c.59-.24 1.13-.56 1.62-.94l2.39.96c.22.08.47 0 .59-.22l1.92-3.32c.12-.22.07-.47-.12-.61l-2.01-1.58zM12 15.6c-1.98 0-3.6-1.62-3.6-3.6s1.62-3.6 3.6-3.6 3.6 1.62 3.6 3.6-1.62 3.6-3.6 3.6z"
      />
    </svg>
  );
}

type SupportRow = {
  repoId: number;
  repoName: string;
  obj: SupportMarkdownObjectDto;
};

type ViewerState =
  | null
  | {
      kind: "repo";
      path: string;
      content: string;
      repoId: number;
    }
  | {
      kind: "support";
      repoId: number;
      fileName: string;
      content: string;
    };

function isMarkdownPath(p: string): boolean {
  return /\.(md|markdown)$/i.test(p);
}

function viewerShowsMarkdownTabs(v: ViewerState): v is NonNullable<ViewerState> {
  if (!v) return false;
  if (v.kind === "support") return true;
  return isMarkdownPath(v.path);
}

export function AdminCellEditorPage() {
  const navigate = useNavigate();
  const isNew = useMatch({ path: "/admin/cells/new", end: true }) != null;
  const { cellId: cellIdStr } = useParams<{ cellId: string }>();
  const cellId = cellIdStr != null ? Number.parseInt(cellIdStr, 10) : NaN;

  const [cellName, setCellName] = useState("");
  const [cellDescription, setCellDescription] = useState("");
  const [loadedCell, setLoadedCell] = useState<CellResponse | null>(null);

  const [existingRepos, setExistingRepos] = useState<CellRepoResponse[]>([]);
  const [pendingIndexed, setPendingIndexed] = useState<PendingIndexed[]>([]);
  const [indexingAdd, setIndexingAdd] = useState(false);
  const [addProgress, setAddProgress] = useState<IngestProgressState | null>(null);

  const [showRepoForm, setShowRepoForm] = useState(false);
  const [repoMode, setRepoMode] = useState<GitConnectionMode>("HTTPS_PUBLIC");
  const [repoUrl, setRepoUrl] = useState("");
  const [repoLocalPath, setRepoLocalPath] = useState("");
  const [repoDisplayName, setRepoDisplayName] = useState("");
  const [repoNamespace, setRepoNamespace] = useState("");
  const [repoTags, setRepoTags] = useState("");
  const [repoUser, setRepoUser] = useState("");
  const [repoToken, setRepoToken] = useState("");
  const [hintReuse, setHintReuse] = useState(false);
  const [repoHintLoading, setRepoHintLoading] = useState(false);
  /** Rama principal detectada (remoto o local); solo lectura. */
  const [repoDefaultBranch, setRepoDefaultBranch] = useState("");

  const [supportRows, setSupportRows] = useState<SupportRow[]>([]);
  const [supportLoading, setSupportLoading] = useState(false);

  const [showSupportModal, setShowSupportModal] = useState(false);
  const [supRepoId, setSupRepoId] = useState<number | "">("");
  const [supHuCode, setSupHuCode] = useState("");
  const [supHuTitle, setSupHuTitle] = useState("");
  const [supFile, setSupFile] = useState<File | null>(null);
  const [supportSaving, setSupportSaving] = useState(false);
  const [supportUploadPhaseIndex, setSupportUploadPhaseIndex] = useState(0);

  /** Filtros del listado de soportes (tarjeta Soportes). "" en repo = todos. */
  const [supportFilterRepoId, setSupportFilterRepoId] = useState<string>("");
  const [supportFilterHu, setSupportFilterHu] = useState("");
  const [supportFilterFile, setSupportFilterFile] = useState("");
  const [supportFiltersOpen, setSupportFiltersOpen] = useState(false);

  const [explorerRepoId, setExplorerRepoId] = useState<number | null>(null);
  const [explorerTree, setExplorerTree] = useState<FolderStructureDto | null>(null);
  const [explorerLoading, setExplorerLoading] = useState(false);
  const [explorerFileSelected, setExplorerFileSelected] = useState<string | null>(null);

  const [viewer, setViewer] = useState<ViewerState>(null);
  const [viewerDraft, setViewerDraft] = useState("");
  const [viewerLoading, setViewerLoading] = useState(false);
  const [viewerSaving, setViewerSaving] = useState(false);
  /** Vista renderizada (como Soporte) vs fuente; solo para .md / soporte. */
  const [mdViewerTab, setMdViewerTab] = useState<"preview" | "markdown">("preview");

  /** Edición inline de nombre/descripción (solo célula existente; «Nueva célula» va siempre en modo formulario). */
  const [editingCellData, setEditingCellData] = useState(false);
  const [savingCellData, setSavingCellData] = useState(false);

  const [err, setErr] = useState<string | null>(null);
  const [loading, setLoading] = useState(!isNew);
  const [saving, setSaving] = useState(false);
  const [repoDeleteModal, setRepoDeleteModal] = useState<
    null | { repo: CellRepoResponse; taskCount: number | null; loading: boolean }
  >(null);

  const reposCombined = useMemo(
    () => mergedRepos(isNew, existingRepos, pendingIndexed),
    [isNew, existingRepos, pendingIndexed],
  );

  const filteredSupportRows = useMemo(() => {
    const rid = supportFilterRepoId.trim();
    const hu = supportFilterHu.trim().toLowerCase();
    const fn = supportFilterFile.trim().toLowerCase();
    return supportRows.filter((row) => {
      if (rid !== "" && String(row.repoId) !== rid) return false;
      const label = (row.obj.displayLabel ?? row.obj.fileName ?? "").toLowerCase();
      const fileName = (row.obj.fileName ?? "").toLowerCase();
      if (hu !== "" && !label.includes(hu)) return false;
      if (fn !== "" && !label.includes(fn) && !fileName.includes(fn)) return false;
      return true;
    });
  }, [supportRows, supportFilterRepoId, supportFilterHu, supportFilterFile]);

  const effectiveCellId = !isNew && loadedCell ? loadedCell.id : null;
  /** Repo indexado en esta sesión pero aún no asignado a la célula en BD → rutas `/pending/*`. */
  const repoIdIsPending = useCallback(
    (repoId: number) => pendingIndexed.some((p) => p.repo.id === repoId),
    [pendingIndexed],
  );
  const hasRepos = reposCombined.length > 0;
  const soporteTitle = (cellName.trim() || loadedCell?.name || "…").trim();

  useEffect(() => {
    if (viewer && viewerShowsMarkdownTabs(viewer)) {
      setMdViewerTab("preview");
    }
  }, [viewer]);

  useEffect(() => {
    if (!getUserId().trim()) {
      navigate("/", { replace: true });
      return;
    }
    if (isSupportRole()) {
      navigate("/support/cells", { replace: true });
    }
  }, [navigate]);

  useEffect(() => {
    if (isNew || Number.isNaN(cellId)) return;
    let cancelled = false;
    (async () => {
      setLoading(true);
      setErr(null);
      try {
        const cells = await fetchCells();
        const c = cells.find((x) => x.id === cellId);
        if (!c) {
          setErr("Célula no encontrada.");
          return;
        }
        if (cancelled) return;
        setLoadedCell(c);
        setCellName(c.name);
        setCellDescription(c.description ?? "");
        const repos = await fetchCellRepos(cellId);
        if (!cancelled) setExistingRepos(repos);
      } catch (e) {
        if (!cancelled) setErr(e instanceof Error ? e.message : String(e));
      } finally {
        if (!cancelled) setLoading(false);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [isNew, cellId]);

  const refreshSupports = useCallback(async () => {
    if (reposCombined.length === 0) {
      setSupportRows([]);
      return;
    }
    setSupportLoading(true);
    setErr(null);
    try {
      const rows: SupportRow[] = [];
      for (const r of reposCombined) {
        const objs = await listSupportMarkdownObjects(r.id);
        for (const o of objs) {
          rows.push({ repoId: r.id, repoName: r.displayName, obj: o });
        }
      }
      setSupportRows(rows);
    } catch (e) {
      setErr(e instanceof Error ? e.message : String(e));
    } finally {
      setSupportLoading(false);
    }
  }, [reposCombined]);

  useEffect(() => {
    void refreshSupports();
  }, [refreshSupports]);

  useEffect(() => {
    if (!supportSaving) return;
    setSupportUploadPhaseIndex(0);
    const id = window.setInterval(() => {
      setSupportUploadPhaseIndex((i) => (i + 1) % SUPPORT_UPLOAD_PHASES.length);
    }, 2600);
    return () => clearInterval(id);
  }, [supportSaving]);

  useEffect(() => {
    if (reposCombined.length === 0) {
      setExplorerRepoId(null);
      setExplorerTree(null);
      return;
    }
    if (explorerRepoId == null || !reposCombined.some((r) => r.id === explorerRepoId)) {
      setExplorerRepoId(reposCombined[0].id);
    }
  }, [reposCombined, explorerRepoId]);

  useEffect(() => {
    if (explorerRepoId == null) return;
    let cancelled = false;
    (async () => {
      setExplorerLoading(true);
      setExplorerTree(null);
      try {
        const usePendingTree =
          repoIdIsPending(explorerRepoId) || effectiveCellId == null;
        const tree = usePendingTree
          ? await adminFetchPendingRepoTree(explorerRepoId)
          : await adminFetchRepoTree(effectiveCellId!, explorerRepoId);
        if (!cancelled) setExplorerTree(tree);
      } catch (e) {
        if (!cancelled) setErr(e instanceof Error ? e.message : String(e));
      } finally {
        if (!cancelled) setExplorerLoading(false);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [explorerRepoId, effectiveCellId, repoIdIsPending]);

  const refreshRepoHint = useCallback(
    async (url: string, localPath: string, mode: GitConnectionMode) => {
      const needUrl = mode !== "LOCAL" && url.trim() === "";
      const needLocal = mode === "LOCAL" && localPath.trim() === "";
      if (needUrl || needLocal) {
        setRepoDisplayName("");
        setRepoNamespace("");
        setHintReuse(false);
        setRepoDefaultBranch("");
        return;
      }
      setRepoHintLoading(true);
      try {
        const hint = await adminRepoUrlHint({
          mode,
          url: mode !== "LOCAL" ? url.trim() : undefined,
          localPath: mode === "LOCAL" ? localPath.trim() : undefined,
        });
        setRepoDisplayName(hint.displayName);
        setRepoNamespace(hint.vectorNamespace);
        setHintReuse(hint.reusedFromExisting);
        const b = hint.defaultBranch?.trim();
        setRepoDefaultBranch(b ?? "");
      } catch {
        setRepoDefaultBranch("");
      } finally {
        setRepoHintLoading(false);
      }
    },
    [],
  );

  useEffect(() => {
    if (repoMode === "LOCAL") return;
    const u = repoUrl.trim();
    if (u.length < 5 || !u.toLowerCase().endsWith(".git")) {
      setRepoDefaultBranch("");
      return;
    }
    const t = window.setTimeout(() => {
      void refreshRepoHint(u, repoLocalPath, repoMode);
    }, 400);
    return () => clearTimeout(t);
  }, [repoUrl, repoMode, repoLocalPath, refreshRepoHint]);

  useEffect(() => {
    if (repoMode !== "LOCAL") return;
    const p = repoLocalPath.trim();
    if (p.length < 2) {
      setRepoDefaultBranch("");
      return;
    }
    const t = window.setTimeout(() => {
      void refreshRepoHint(repoUrl, p, "LOCAL");
    }, 400);
    return () => clearTimeout(t);
  }, [repoLocalPath, repoMode, repoUrl, refreshRepoHint]);

  function onRepoUrlInput(v: string) {
    setRepoUrl(v);
    const lo = v.trim().toLowerCase();
    if ((repoMode === "HTTPS_PUBLIC" || repoMode === "HTTPS_AUTH") && lo.endsWith(".git")) {
      const localName = parseGitRepoNameFromHttpsUrl(v);
      if (localName) {
        setRepoDisplayName(localName);
        setRepoNamespace(newVectorNamespaceFromRepoName(localName));
        setHintReuse(false);
      }
    }
  }

  async function addAndIndexRepo() {
    setErr(null);
    if (repoMode === "LOCAL") {
      if (!repoLocalPath.trim()) {
        setErr("Indica la ruta local.");
        return;
      }
    } else {
      if (!repoUrl.trim()) {
        setErr("Indica la URL del repositorio.");
        return;
      }
      if (repoMode === "HTTPS_AUTH" && !repoToken.trim()) {
        setErr("El token es obligatorio para HTTPS con autenticación.");
        return;
      }
    }
    if (!repoDisplayName.trim() || !repoNamespace.trim()) {
      setErr("Nombre y namespace deben estar rellenos (se calculan al completar la URL).");
      return;
    }
    const body = toRepoBodyFromForm({
      mode: repoMode,
      repositoryUrl: repoUrl,
      localPath: repoLocalPath,
      displayName: repoDisplayName.trim(),
      vectorNamespace: repoNamespace.trim(),
      tagsCsv: repoTags,
      gitUsername: repoUser,
      credentialPlain: repoToken,
    });
    setIndexingAdd(true);
    setAddProgress({
      totalFiles: 0,
      filesProcessed: 0,
      chunksIndexed: 0,
      currentFile: null,
      detail: null,
      skippedHint: null,
    });
    try {
      const res = await adminIndexRepoStream(body, (ev) => {
        setAddProgress((prev) => mergeIngestProgress(prev, ev));
      });
      setPendingIndexed((prev) =>
        prev.some((p) => p.repo.id === res.id) ? prev : [...prev, { clientId: newId(), repo: res }],
      );
      setRepoUrl("");
      setRepoLocalPath("");
      setRepoDisplayName("");
      setRepoNamespace("");
      setRepoTags("");
      setRepoToken("");
      setHintReuse(false);
      setRepoDefaultBranch("");
      setShowRepoForm(false);
    } catch (ex) {
      setErr(ex instanceof Error ? ex.message : String(ex));
    } finally {
      setIndexingAdd(false);
      setAddProgress(null);
    }
  }

  async function openRemoveRepoModal(r: CellRepoResponse) {
    if (!loadedCell) return;
    setRepoDeleteModal({ repo: r, taskCount: null, loading: true });
    setErr(null);
    try {
      const { taskCount } = await adminFetchRepoDeleteImpact(loadedCell.id, r.id);
      setRepoDeleteModal({ repo: r, taskCount, loading: false });
    } catch (ex) {
      setErr(ex instanceof Error ? ex.message : String(ex));
      setRepoDeleteModal(null);
    }
  }

  async function confirmRemoveExistingRepo() {
    if (!loadedCell || !repoDeleteModal || repoDeleteModal.loading || repoDeleteModal.taskCount === null) return;
    const r = repoDeleteModal.repo;
    setErr(null);
    try {
      await adminDeleteRepo(loadedCell.id, r.id);
      setRepoDeleteModal(null);
      setExistingRepos((list) => list.filter((x) => x.id !== r.id));
      void refreshSupports();
    } catch (ex) {
      setErr(ex instanceof Error ? ex.message : String(ex));
    }
  }

  async function removePendingIndexed(p: PendingIndexed) {
    if (indexingAdd) return;
    setErr(null);
    try {
      await adminDeletePendingRepo(p.repo.id);
      setPendingIndexed((list) => list.filter((x) => x.clientId !== p.clientId));
      void refreshSupports();
    } catch (ex) {
      setErr(ex instanceof Error ? ex.message : String(ex));
    }
  }

  async function openRepoViewer(relPath: string) {
    if (explorerRepoId == null) return;
    setViewerLoading(true);
    setErr(null);
    try {
      const usePendingFile =
        repoIdIsPending(explorerRepoId) || effectiveCellId == null;
      const fc = usePendingFile
        ? await adminFetchPendingRepoFile(explorerRepoId, relPath)
        : await adminFetchRepoFile(effectiveCellId!, explorerRepoId, relPath);
      setViewer({ kind: "repo", path: relPath, content: fc.content ?? "", repoId: explorerRepoId });
      setViewerDraft(fc.content ?? "");
    } catch (ex) {
      setErr(ex instanceof Error ? ex.message : String(ex));
    } finally {
      setViewerLoading(false);
    }
  }

  async function openSupportViewer(repoId: number, fileName: string, url: string) {
    setViewerLoading(true);
    setErr(null);
    try {
      const text = await fetchTextFromPresignedUrl(url);
      setViewer({ kind: "support", repoId, fileName, content: text });
      setViewerDraft(text);
    } catch (ex) {
      setErr(ex instanceof Error ? ex.message : String(ex));
    } finally {
      setViewerLoading(false);
    }
  }

  async function saveSupportViewer() {
    if (viewer?.kind !== "support") return;
    setViewerSaving(true);
    setErr(null);
    try {
      if (effectiveCellId != null && !repoIdIsPending(viewer.repoId)) {
        await adminUpdateCellSupportMarkdown(effectiveCellId, viewer.repoId, viewer.fileName, viewerDraft);
      } else {
        await adminUpdatePendingSupportMarkdown(viewer.repoId, viewer.fileName, viewerDraft);
      }
      setViewer({ ...viewer, content: viewerDraft });
      void refreshSupports();
    } catch (ex) {
      setErr(ex instanceof Error ? ex.message : String(ex));
    } finally {
      setViewerSaving(false);
    }
  }

  async function deleteSupportRow(row: SupportRow) {
    const label = row.obj.fileName;
    if (!window.confirm(`¿Eliminar el soporte «${label}» y su indexación?`)) return;
    setErr(null);
    try {
      if (effectiveCellId != null && !repoIdIsPending(row.repoId)) {
        await adminDeleteCellSupportMarkdown(effectiveCellId, row.repoId, row.obj.fileName);
      } else {
        await adminDeletePendingSupportMarkdown(row.repoId, row.obj.fileName);
      }
      if (viewer?.kind === "support" && viewer.fileName === row.obj.fileName) {
        setViewer(null);
      }
      void refreshSupports();
    } catch (ex) {
      setErr(ex instanceof Error ? ex.message : String(ex));
    }
  }

  async function submitSupportModal(e: FormEvent) {
    e.preventDefault();
    if (supRepoId === "" || supFile == null || !supHuCode.trim() || !supHuTitle.trim()) {
      setErr("Completa repositorio, código HU, título y archivo .md.");
      return;
    }
    setSupportSaving(true);
    setErr(null);
    try {
      if (effectiveCellId != null && !repoIdIsPending(supRepoId)) {
        await adminUploadCellSupportMarkdown(effectiveCellId, supRepoId, supFile, supHuCode.trim(), supHuTitle.trim());
      } else {
        await adminUploadPendingSupportMarkdown(supRepoId, supFile, supHuCode.trim(), supHuTitle.trim());
      }
      setShowSupportModal(false);
      setSupRepoId("");
      setSupHuCode("");
      setSupHuTitle("");
      setSupFile(null);
      void refreshSupports();
    } catch (ex) {
      setErr(ex instanceof Error ? ex.message : String(ex));
    } finally {
      setSupportSaving(false);
    }
  }

  async function onSave(e: FormEvent) {
    e.preventDefault();
    setErr(null);
    if (!cellName.trim()) {
      setErr("El nombre de la célula es obligatorio.");
      return;
    }
    setSaving(true);
    try {
      let targetCellId: number;
      if (isNew) {
        const created = await adminCreateCell({
          name: cellName.trim(),
          description: cellDescription.trim() || undefined,
        });
        targetCellId = created.id;
      } else {
        if (!loadedCell) throw new Error("Célula no cargada.");
        await adminUpdateCell(loadedCell.id, {
          name: cellName.trim(),
          description: cellDescription.trim() || undefined,
        });
        targetCellId = loadedCell.id;
      }
      if (pendingIndexed.length > 0) {
        await adminAssignReposToCell(
          targetCellId,
          pendingIndexed.map((p) => p.repo.id),
        );
      }
      setPendingIndexed([]);
      navigate("/admin/cells");
    } catch (ex) {
      setErr(ex instanceof Error ? ex.message : String(ex));
    } finally {
      setSaving(false);
    }
  }

  function cancelCellDataEdit() {
    if (!loadedCell) return;
    setCellName(loadedCell.name);
    setCellDescription(loadedCell.description ?? "");
    setEditingCellData(false);
    setErr(null);
  }

  async function saveCellDataEdits() {
    if (!loadedCell) return;
    setErr(null);
    if (!cellName.trim()) {
      setErr("El nombre de la célula es obligatorio.");
      return;
    }
    setSavingCellData(true);
    try {
      const updated = await adminUpdateCell(loadedCell.id, {
        name: cellName.trim(),
        description: cellDescription.trim() || undefined,
      });
      setLoadedCell(updated);
      setCellName(updated.name);
      setCellDescription(updated.description ?? "");
      setEditingCellData(false);
    } catch (ex) {
      setErr(ex instanceof Error ? ex.message : String(ex));
    } finally {
      setSavingCellData(false);
    }
  }

  async function onCancel() {
    setErr(null);
    if (pendingIndexed.length > 0) {
      const ok = window.confirm(
        "Hay repositorios indexados que aún no están guardados en la célula. Se eliminarán de la base de datos y su indexación vectorial. ¿Continuar?",
      );
      if (!ok) return;
      setSaving(true);
      try {
        for (const p of pendingIndexed) {
          await adminDeletePendingRepo(p.repo.id);
        }
        setPendingIndexed([]);
        navigate("/admin/cells");
      } catch (ex) {
        setErr(ex instanceof Error ? ex.message : String(ex));
      } finally {
        setSaving(false);
      }
      return;
    }
    navigate("/admin/cells");
  }

  if (!isNew && Number.isNaN(cellId)) {
    return (
      <div className="page connect-page">
        <p className="muted">Ruta no válida.</p>
      </div>
    );
  }

  const supportEmpty = supportRows.length === 0;

  return (
    <div className="page connect-page admin-cell-editor">
      <button
        type="button"
        className="admin-back-btn"
        onClick={() => navigate("/admin/cells")}
        aria-label="Volver"
        title="Volver"
      >
        ←
      </button>

      <header className="page__header">
        <h1>{isNew ? "Nueva célula" : "Editar célula"}</h1>
        <p className="muted">
          {isNew
            ? "Define la célula. El botón + en «Repositorios actuales» indexa al momento; «Guardar» asocia los pendientes."
            : "El + añade repositorios indexados al momento; «Guardar» actualiza datos y asocia pendientes."}
        </p>
      </header>

      {err && (
        <p className="muted small" role="alert">
          {err}
        </p>
      )}

      {loading ? (
        <p className="muted small">Cargando…</p>
      ) : (
        <form onSubmit={onSave} className="admin-cell-editor__form">
          <div className="admin-cell-editor__layout">
            <div className="admin-cell-editor__main">
              <section className="card admin-cell-editor__cell-identity">
                {isNew ? (
                  <>
                    <p className="admin-cell-editor__cell-identity-eyebrow">Nueva célula</p>
                    <label className="field">
                      <span>Nombre (identificador único)</span>
                      <input value={cellName} onChange={(ev) => setCellName(ev.target.value)} required maxLength={200} />
                    </label>
                    <label className="field">
                      <span>Descripción</span>
                      <textarea value={cellDescription} onChange={(ev) => setCellDescription(ev.target.value)} rows={2} />
                    </label>
                  </>
                ) : editingCellData ? (
                  <>
                    <div className="admin-cell-editor__cell-identity-header">
                      <span className="admin-cell-editor__cell-identity-eyebrow">Editar célula</span>
                    </div>
                    <label className="field">
                      <span>Nombre (identificador único)</span>
                      <input value={cellName} onChange={(ev) => setCellName(ev.target.value)} required maxLength={200} />
                    </label>
                    <label className="field">
                      <span>Descripción</span>
                      <textarea value={cellDescription} onChange={(ev) => setCellDescription(ev.target.value)} rows={3} />
                    </label>
                    <div className="admin-cell-editor__cell-data-actions">
                      <button
                        type="button"
                        className="btn primary"
                        disabled={savingCellData || saving || indexingAdd}
                        onClick={() => void saveCellDataEdits()}
                      >
                        {savingCellData ? "Guardando…" : "Guardar cambios"}
                      </button>
                      <button
                        type="button"
                        className="btn"
                        disabled={savingCellData}
                        onClick={() => cancelCellDataEdit()}
                      >
                        Cancelar
                      </button>
                    </div>
                  </>
                ) : (
                  <>
                    <div className="admin-cell-editor__cell-identity-header">
                      <h2 className="admin-cell-editor__cell-identity-title">{cellName.trim() || "—"}</h2>
                      <button
                        type="button"
                        className="admin-icon-btn admin-cell-editor__cell-edit-btn"
                        title="Editar nombre y descripción"
                        aria-label="Editar datos de la célula"
                        disabled={saving || savingCellData || indexingAdd}
                        onClick={() => setEditingCellData(true)}
                      >
                        <svg width="16" height="16" viewBox="0 0 24 24" aria-hidden>
                          <path
                            fill="currentColor"
                            d="M3 17.25V21h3.75L17.81 9.94l-3.75-3.75L3 17.25zM20.71 7.04a1.003 1.003 0 0 0 0-1.41l-2.34-2.34a1.003 1.003 0 0 0-1.41 0l-1.83 1.83 3.75 3.75 1.83-1.83z"
                          />
                        </svg>
                      </button>
                    </div>
                    <p className="admin-cell-editor__cell-identity-desc">
                      {cellDescription.trim() !== "" ? cellDescription : <span className="muted">Sin descripción.</span>}
                    </p>
                  </>
                )}
              </section>

              <section className="card">
                <div className="admin-cell-editor__repo-actions">
                  <h2 className="h3">Repositorios actuales</h2>
                  <button
                    type="button"
                    className="admin-cell-editor__fab-green"
                    title="Agregar repositorio"
                    aria-label="Agregar repositorio"
                    disabled={indexingAdd || saving}
                    onClick={() => setShowRepoForm((v) => !v)}
                  >
                    +
                  </button>
                </div>

                {!isNew && existingRepos.length > 0 && (
                  <ul className="admin-cell-editor__repo-list">
                    {existingRepos.map((r) => (
                      <li key={r.id} className="admin-cell-editor__repo-li">
                        <span>
                          <strong>{r.displayName}</strong>
                          {r.linkedWithoutReindex && (
                            <span className="muted small"> · enlazado sin reindexar</span>
                          )}
                          {r.lastIngestAt != null && (
                            <span className="muted small">
                              {" "}
                              · {r.lastIngestFiles ?? 0} arch., {r.lastIngestChunks ?? 0} frag.
                            </span>
                          )}
                          {r.lastIngestSkipped != null && r.lastIngestSkipped.length > 0 && (
                            <span
                              className="muted small"
                              title={r.lastIngestSkipped.join("\n")}
                            >
                              {" "}
                              · omitidos: {summarizeSkippedPaths(r.lastIngestSkipped)}
                            </span>
                          )}
                        </span>
                        <button
                          type="button"
                          className="admin-icon-btn admin-icon-btn--danger"
                          title="Quitar de la célula"
                          aria-label="Eliminar repositorio"
                          disabled={repoDeleteModal?.loading}
                          onClick={() => void openRemoveRepoModal(r)}
                        >
                          ×
                        </button>
                      </li>
                    ))}
                  </ul>
                )}

                {pendingIndexed.length > 0 && (
                  <ul className="admin-cell-editor__staged">
                    {pendingIndexed.map((p) => (
                      <li key={p.clientId} className="admin-cell-editor__staged-li">
                        <span>
                          <strong>{p.repo.displayName}</strong>{" "}
                          <span className="muted small">
                            {p.repo.connectionMode} · {p.repo.vectorNamespace ?? ""}
                            {p.repo.lastIngestFiles != null && (
                              <>
                                {" "}
                                · {p.repo.lastIngestFiles} arch., {p.repo.lastIngestChunks ?? 0} frag.
                              </>
                            )}
                            {p.repo.lastIngestSkipped != null && p.repo.lastIngestSkipped.length > 0 && (
                              <>
                                {" "}
                                · omitidos: {summarizeSkippedPaths(p.repo.lastIngestSkipped)}
                              </>
                            )}
                            <span className="muted"> · pendiente de guardar</span>
                          </span>
                        </span>
                        <button
                          type="button"
                          className="admin-icon-btn admin-icon-btn--danger"
                          aria-label="Quitar y borrar indexación"
                          title="Elimina el repo pendiente y su indexación"
                          disabled={indexingAdd || saving}
                          onClick={() => removePendingIndexed(p)}
                        >
                          ×
                        </button>
                      </li>
                    ))}
                  </ul>
                )}

                {showRepoForm && (
                  <div className="admin-repo-form admin-repo-form--panel">
                    <label className="field">
                      <span>Modo</span>
                      <select
                        value={repoMode}
                        onChange={(ev) => {
                          const m = ev.target.value as GitConnectionMode;
                          setRepoMode(m);
                          void refreshRepoHint(repoUrl, repoLocalPath, m);
                        }}
                      >
                        <option value="HTTPS_PUBLIC">HTTPS público</option>
                        <option value="HTTPS_AUTH">HTTPS con token</option>
                        <option value="LOCAL">Ruta local</option>
                      </select>
                    </label>
                    {repoMode !== "LOCAL" ? (
                      <label className="field">
                        <span>URL del repositorio</span>
                        <input
                          value={repoUrl}
                          onChange={(ev) => onRepoUrlInput(ev.target.value)}
                          onPaste={(ev) => {
                            const el = ev.currentTarget;
                            window.setTimeout(() => onRepoUrlInput(el.value), 0);
                          }}
                          autoComplete="off"
                        />
                      </label>
                    ) : (
                      <label className="field">
                        <span>Ruta local</span>
                        <input
                          value={repoLocalPath}
                          onChange={(ev) => {
                            const v = ev.target.value;
                            setRepoLocalPath(v);
                            void refreshRepoHint(repoUrl, v, "LOCAL");
                          }}
                          autoComplete="off"
                        />
                      </label>
                    )}
                    {repoMode === "HTTPS_AUTH" && (
                      <>
                        <label className="field">
                          <span>Usuario Git (opcional)</span>
                          <input value={repoUser} onChange={(ev) => setRepoUser(ev.target.value)} />
                        </label>
                        <label className="field">
                          <span>Token / contraseña</span>
                          <input
                            type="password"
                            value={repoToken}
                            onChange={(ev) => setRepoToken(ev.target.value)}
                            autoComplete="off"
                          />
                        </label>
                      </>
                    )}
                    <label className="field">
                      <span>Rama principal (detectada)</span>
                      <input
                        className="admin-repo-form__auto-field"
                        value={repoHintLoading ? "…" : repoDefaultBranch || "—"}
                        readOnly
                        disabled
                        tabIndex={-1}
                        title="Rama por defecto del remoto (HEAD) o rama actual en ruta local. Se obtiene al validar la URL o la ruta."
                        aria-readonly="true"
                      />
                      {!repoHintLoading && repoDefaultBranch === "" && repoMode !== "LOCAL" && repoUrl.trim().endsWith(".git") && (
                        <span className="muted small">No se pudo leer el remoto (red privada o URL incorrecta).</span>
                      )}
                    </label>
                    <label className="field">
                      <span>Nombre visible</span>
                      <input
                        className="admin-repo-form__auto-field"
                        value={repoDisplayName}
                        readOnly
                        tabIndex={-1}
                        placeholder="Se rellena al indicar la URL (terminada en .git) o ruta"
                      />
                      {repoHintLoading && <span className="muted small">Sincronizando con el servidor…</span>}
                      {hintReuse && !repoHintLoading && (
                        <span className="muted small">Datos reutilizados del repositorio ya registrado.</span>
                      )}
                    </label>
                    <label className="field">
                      <span>Etiquetas (CSV, opcional)</span>
                      <input value={repoTags} onChange={(ev) => setRepoTags(ev.target.value)} placeholder="main, docs" />
                    </label>
                    <label className="field">
                      <span>Namespace vectorial</span>
                      <input
                        className="admin-repo-form__auto-field"
                        value={repoNamespace}
                        readOnly
                        tabIndex={-1}
                        placeholder="Se genera al completar la URL"
                      />
                    </label>
                    <button
                      type="button"
                      className="btn primary admin-repo-form__add-to-list"
                      disabled={indexingAdd || saving}
                      onClick={() => void addAndIndexRepo()}
                    >
                      {indexingAdd ? "Indexando…" : "Añadir al listado"}
                    </button>
                    {indexingAdd && addProgress && (
                      <div className="ingest-progress ingest-progress--bar admin-cell-editor__ingest-box" aria-live="polite">
                        <p className="ingest-progress__lead ingest-progress__lead--bar small muted">
                          Indexando → vector…
                        </p>
                        {addProgress.currentFile ? (
                          <div
                            className="ingest-progress__file ingest-progress__file--bar ingest-progress__file--primary"
                            title={addProgress.currentFile}
                          >
                            <span className="muted">Archivo actual:</span>{" "}
                            <code className="ingest-progress__file-path">{addProgress.currentFile}</code>
                          </div>
                        ) : null}
                        <div className="ingest-progress__stats ingest-progress__stats--bar">
                          {addProgress.totalFiles > 0 ? (
                            <>
                              Archivos:{" "}
                              <strong>
                                {addProgress.filesProcessed} / {addProgress.totalFiles}
                              </strong>
                              <span className="muted"> · Chunks: {addProgress.chunksIndexed}</span>
                            </>
                          ) : (
                            <span className="muted">
                              {addProgress.detail?.trim()
                                ? addProgress.detail
                                : "Preparando… (si acabas de pulsar, primero se clona el repo; puede tardar sin barra de porcentaje)."}
                            </span>
                          )}
                        </div>
                        {addProgress.detail && addProgress.totalFiles > 0 ? (
                          <div className="ingest-progress__detail ingest-progress__detail--bar small muted">
                            {addProgress.detail}
                          </div>
                        ) : null}
                        {addProgress.skippedHint && (
                          <div className="ingest-progress__detail ingest-progress__detail--bar small muted">
                            Omisiones o fallos: {addProgress.skippedHint}
                          </div>
                        )}
                        <div
                          className={
                            "ingest-progress__track ingest-progress__track--bar" +
                            (addProgress.totalFiles === 0 ? " ingest-progress__track--indeterminate" : "")
                          }
                        >
                          <div
                            className="ingest-progress__fill"
                            style={{
                              width:
                                addProgress.totalFiles > 0
                                  ? `${Math.min(
                                      100,
                                      (addProgress.filesProcessed / addProgress.totalFiles) * 100,
                                    )}%`
                                  : "30%",
                            }}
                          />
                        </div>
                      </div>
                    )}
                  </div>
                )}
              </section>

              <section className="card admin-cell-editor__soportes-card">
                <div
                  className={
                    supportEmpty
                      ? "admin-cell-editor__soportes-header admin-cell-editor__soportes-header--empty"
                      : "admin-cell-editor__soportes-header"
                  }
                >
                  <h2 className="h3">Soportes {soporteTitle}</h2>
                  <div className="admin-cell-editor__soportes-header-actions">
                    {!supportEmpty && supportRows.length > 0 && (
                      <button
                        type="button"
                        className={
                          "admin-cell-editor__soportes-filter-toggle" +
                          (supportFiltersOpen ? " is-open" : "") +
                          (supportFilterRepoId !== "" ||
                          supportFilterHu.trim() !== "" ||
                          supportFilterFile.trim() !== ""
                            ? " has-active-filters"
                            : "")
                        }
                        title={supportFiltersOpen ? "Ocultar filtros" : "Mostrar filtros"}
                        aria-expanded={supportFiltersOpen}
                        aria-controls="admin-soportes-filters-panel"
                        id="admin-soportes-filter-trigger"
                        onClick={() => setSupportFiltersOpen((o) => !o)}
                      >
                        <svg width="18" height="18" viewBox="0 0 24 24" aria-hidden>
                          <path
                            fill="currentColor"
                            d="M10 18h4v-2h-4v2zM3 6v2h18V6H3zm3 7h12v-2H6v2z"
                          />
                        </svg>
                      </button>
                    )}
                    <button
                      type="button"
                      className={
                        supportEmpty
                          ? "admin-cell-editor__fab-green admin-cell-editor__fab-green--large"
                          : "admin-cell-editor__fab-green"
                      }
                      title={hasRepos ? "Agregar soporte" : "Añade primero un repositorio"}
                      aria-label="Agregar soporte"
                      disabled={!hasRepos || indexingAdd || saving || supportLoading}
                      onClick={() => {
                        if (!hasRepos) return;
                        setShowSupportModal(true);
                        if (reposCombined.length === 1) setSupRepoId(reposCombined[0].id);
                      }}
                    >
                      +
                    </button>
                  </div>
                </div>
                {supportLoading && <p className="muted small">Cargando soportes…</p>}
                {!supportLoading && supportRows.length > 0 && supportFiltersOpen && (
                  <div
                    className="admin-cell-editor__soportes-filters"
                    id="admin-soportes-filters-panel"
                    role="region"
                    aria-labelledby="admin-soportes-filter-trigger"
                  >
                    <label className="field admin-cell-editor__soportes-filter-field">
                      <span>Filtrar por repositorio</span>
                      <select
                        value={supportFilterRepoId}
                        onChange={(ev) => setSupportFilterRepoId(ev.target.value)}
                        aria-label="Filtrar por repositorio"
                      >
                        <option value="">Todos los repositorios</option>
                        {reposCombined.map((r) => (
                          <option key={r.id} value={String(r.id)}>
                            {r.displayName}
                          </option>
                        ))}
                      </select>
                    </label>
                    <label className="field admin-cell-editor__soportes-filter-field">
                      <span>Código HU</span>
                      <input
                        type="search"
                        value={supportFilterHu}
                        onChange={(ev) => setSupportFilterHu(ev.target.value)}
                        placeholder="p. ej. HU-002"
                        autoComplete="off"
                        aria-label="Filtrar por código HU"
                      />
                    </label>
                    <label className="field admin-cell-editor__soportes-filter-field">
                      <span>Nombre de archivo</span>
                      <input
                        type="search"
                        value={supportFilterFile}
                        onChange={(ev) => setSupportFilterFile(ev.target.value)}
                        placeholder="p. ej. ENTREGABLE.md"
                        autoComplete="off"
                        aria-label="Filtrar por nombre de archivo"
                      />
                    </label>
                    {(supportFilterRepoId !== "" ||
                      supportFilterHu.trim() !== "" ||
                      supportFilterFile.trim() !== "") && (
                      <button
                        type="button"
                        className="btn admin-cell-editor__soportes-filter-clear"
                        onClick={() => {
                          setSupportFilterRepoId("");
                          setSupportFilterHu("");
                          setSupportFilterFile("");
                        }}
                      >
                        Limpiar filtros
                      </button>
                    )}
                  </div>
                )}
                {!supportLoading && supportRows.length > 0 && filteredSupportRows.length === 0 && (
                  <p className="muted small admin-cell-editor__soportes-no-match">
                    Ningún soporte coincide con los filtros.
                  </p>
                )}
                {!supportLoading && supportRows.length > 0 && filteredSupportRows.length > 0 && (
                  <ul className="admin-cell-editor__repo-list">
                    {filteredSupportRows.map((row) => (
                      <li key={`${row.repoId}-${row.obj.fileName}`} className="admin-cell-editor__repo-li">
                        <span>
                          <span className="muted small">{row.repoName} · </span>
                          <strong>{row.obj.displayLabel ?? row.obj.fileName}</strong>
                        </span>
                        <span className="admin-cell-editor__row-actions">
                          <button
                            type="button"
                            className="admin-icon-btn"
                            title="Visualizar"
                            aria-label="Visualizar soporte"
                            onClick={() => void openSupportViewer(row.repoId, row.obj.fileName, row.obj.url)}
                          >
                            <svg width="14" height="14" viewBox="0 0 24 24" aria-hidden>
                              <path
                                fill="currentColor"
                                d="M12 4.5C7 4.5 2.73 7.61 1 12c1.73 4.39 6 7.5 11 7.5s9.27-3.11 11-7.5c-1.73-4.39-6-7.5-11-7.5zM12 17c-2.76 0-5-2.24-5-5s2.24-5 5-5 5 2.24 5 5-2.24 5-5 5zm0-8c-1.66 0-3 1.34-3 3s1.34 3 3 3 3-1.34 3-3-1.34-3-3-3z"
                              />
                            </svg>
                          </button>
                          <button
                            type="button"
                            className="admin-icon-btn admin-icon-btn--danger"
                            title="Eliminar"
                            aria-label="Eliminar soporte"
                            onClick={() => void deleteSupportRow(row)}
                          >
                            ×
                          </button>
                        </span>
                      </li>
                    ))}
                  </ul>
                )}
              </section>

              <div className="admin-cell-editor__save-wrap admin-cell-editor__save-actions">
                <button type="submit" className="btn primary admin-cell-editor__save-btn" disabled={saving || indexingAdd}>
                  {saving ? "Guardando…" : "Guardar"}
                </button>
                <button
                  type="button"
                  className="btn admin-cell-editor__cancel-btn"
                  disabled={saving || indexingAdd}
                  onClick={() => void onCancel()}
                >
                  Cancelar
                </button>
              </div>
            </div>

            {hasRepos && (
              <aside className="card admin-cell-editor__aside">
                <h2 className="h3">Explorador</h2>
                <label className="field">
                  <span>Repositorio</span>
                  <select
                    value={explorerRepoId ?? ""}
                    onChange={(ev) => {
                      const v = ev.target.value;
                      setExplorerRepoId(v === "" ? null : Number.parseInt(v, 10));
                      setExplorerFileSelected(null);
                    }}
                  >
                    {reposCombined.map((r) => (
                      <option key={r.id} value={r.id}>
                        {r.displayName}
                      </option>
                    ))}
                  </select>
                </label>
                <h3 className="h4 admin-cell-editor__aside-sub">Archivos del repositorio</h3>
                {explorerLoading && <p className="muted small">Cargando árbol…</p>}
                {!explorerLoading && explorerTree && (
                  <FolderTree
                    key={explorerRepoId ?? "tree"}
                    root={explorerTree}
                    selectedPath={explorerFileSelected}
                    onSelectFile={(rel) => {
                      setExplorerFileSelected(rel);
                      void openRepoViewer(rel);
                    }}
                    onViewFile={(rel) => void openRepoViewer(rel)}
                  />
                )}
                {!explorerLoading &&
                  explorerTree &&
                  (explorerTree.archivos?.length ?? 0) === 0 &&
                  (explorerTree.folders?.length ?? 0) === 0 && (
                    <p className="muted small">Este repositorio no tiene archivos rastreados visibles.</p>
                  )}
              </aside>
            )}
          </div>
        </form>
      )}

      {repoDeleteModal && (
        <div
          className="modal-overlay"
          role="presentation"
          onClick={() => !repoDeleteModal.loading && setRepoDeleteModal(null)}
        >
          <div
            className="modal-card card"
            role="dialog"
            aria-modal="true"
            aria-labelledby="admin-delete-repo-title"
            onClick={(ev) => ev.stopPropagation()}
          >
            <h2 id="admin-delete-repo-title" className="h3">
              Quitar repositorio
            </h2>
            {repoDeleteModal.loading ? (
              <p className="muted small">Calculando impacto…</p>
            ) : (
              <>
                <p>
                  Se eliminará el repositorio <strong>«{repoDeleteModal.repo.displayName}»</strong>, su indexación
                  vectorial y soportes en S3 asociados a su namespace.
                </p>
                <p className="admin-delete-impact">
                  <strong>{repoDeleteModal.taskCount}</strong>{" "}
                  {repoDeleteModal.taskCount === 1
                    ? "tarea vinculada a este repo se eliminará"
                    : "tareas vinculadas a este repo se eliminarán"}
                  .
                </p>
              </>
            )}
            <div className="admin-cell-editor__modal-actions">
              <button
                type="button"
                className="btn"
                disabled={repoDeleteModal.loading}
                onClick={() => setRepoDeleteModal(null)}
              >
                Cancelar
              </button>
              <button
                type="button"
                className="btn primary"
                disabled={repoDeleteModal.loading || repoDeleteModal.taskCount === null}
                onClick={() => void confirmRemoveExistingRepo()}
              >
                Eliminar definitivamente
              </button>
            </div>
          </div>
        </div>
      )}

      {showSupportModal && (
        <div className="modal-overlay" role="presentation" onClick={() => !supportSaving && setShowSupportModal(false)}>
          <div
            className="modal-card card"
            role="dialog"
            aria-modal="true"
            aria-labelledby="support-modal-title"
            onClick={(ev) => ev.stopPropagation()}
          >
            <h2 id="support-modal-title" className="h3">
              Nuevo soporte
            </h2>
            <form onSubmit={(e) => void submitSupportModal(e)}>
              <label className="field">
                <span>Repositorio</span>
                <select
                  required
                  value={supRepoId === "" ? "" : String(supRepoId)}
                  onChange={(ev) => setSupRepoId(ev.target.value === "" ? "" : Number.parseInt(ev.target.value, 10))}
                >
                  <option value="">— Elegir —</option>
                  {reposCombined.map((r) => (
                    <option key={r.id} value={r.id}>
                      {r.displayName}
                    </option>
                  ))}
                </select>
              </label>
              <label className="field">
                <span>Código HU</span>
                <input value={supHuCode} onChange={(ev) => setSupHuCode(ev.target.value)} required />
              </label>
              <label className="field">
                <span>Título HU</span>
                <input value={supHuTitle} onChange={(ev) => setSupHuTitle(ev.target.value)} required />
              </label>
              <label className="field">
                <span>Archivo .md</span>
                <input
                  type="file"
                  accept=".md,text/markdown"
                  onChange={(ev) => setSupFile(ev.target.files?.[0] ?? null)}
                  required
                />
              </label>
              <div className="admin-cell-editor__modal-actions">
                <button type="button" className="btn" disabled={supportSaving} onClick={() => setShowSupportModal(false)}>
                  Cerrar
                </button>
                <button type="submit" className="btn primary" disabled={supportSaving}>
                  {supportSaving ? "Subiendo…" : "Subir e indexar"}
                </button>
              </div>
              {supportSaving && (
                <div className="admin-support-upload-progress ingest-progress ingest-progress--bar" aria-live="polite">
                  <div className="admin-support-upload-progress__head">
                    <span className="admin-support-upload-progress__gear" aria-hidden>
                      <SupportUploadGearIcon />
                    </span>
                    <span className="admin-support-upload-progress__title">Indexando soporte</span>
                  </div>
                  <p className="ingest-progress__detail ingest-progress__detail--bar small muted admin-support-upload-progress__phase">
                    {SUPPORT_UPLOAD_PHASES[supportUploadPhaseIndex]}
                  </p>
                  <p className="ingest-progress__lead ingest-progress__lead--bar small muted">
                    S3 → extracción de texto → embeddings → pgvector (namespace del repo)
                  </p>
                  <div className="ingest-progress__track ingest-progress__track--bar ingest-progress__track--indeterminate">
                    <div className="ingest-progress__fill" style={{ width: "32%" }} />
                  </div>
                </div>
              )}
            </form>
          </div>
        </div>
      )}

      {viewer && (
        <div
          className="modal-overlay modal-overlay--viewer"
          role="presentation"
          onClick={() => !viewerSaving && setViewer(null)}
        >
          <div
            className="modal-card card admin-cell-editor__viewer-modal"
            role="dialog"
            aria-modal="true"
            onClick={(ev) => ev.stopPropagation()}
          >
            <h2 className="admin-cell-editor__viewer-title">
              {viewer.kind === "repo"
                ? `Archivo: ${viewer.path}`
                : `Soporte · ${viewer.fileName}`}
            </h2>
            {viewer.kind === "support" && (
              <p className="muted small admin-cell-editor__viewer-meta">Markdown de soporte (editable)</p>
            )}
            {viewerLoading ? (
              <p className="muted small admin-cell-editor__viewer-loading">Cargando…</p>
            ) : viewerShowsMarkdownTabs(viewer) ? (
              <>
                <div className="admin-cell-editor__md-tabs" role="tablist" aria-label="Vista del archivo">
                  <button
                    type="button"
                    role="tab"
                    id="admin-md-tab-preview"
                    aria-controls="admin-md-panel"
                    aria-selected={mdViewerTab === "preview"}
                    className={"admin-cell-editor__md-tab" + (mdViewerTab === "preview" ? " is-active" : "")}
                    onClick={() => setMdViewerTab("preview")}
                  >
                    Preview
                  </button>
                  <button
                    type="button"
                    role="tab"
                    id="admin-md-tab-markdown"
                    aria-controls="admin-md-panel"
                    aria-selected={mdViewerTab === "markdown"}
                    className={"admin-cell-editor__md-tab" + (mdViewerTab === "markdown" ? " is-active" : "")}
                    onClick={() => setMdViewerTab("markdown")}
                  >
                    Markdown
                  </button>
                </div>
                <div
                  id="admin-md-panel"
                  role="tabpanel"
                  aria-labelledby={mdViewerTab === "preview" ? "admin-md-tab-preview" : "admin-md-tab-markdown"}
                  className="admin-cell-editor__md-panel"
                >
                  {mdViewerTab === "preview" ? (
                    <div className="admin-cell-editor__md-preview">
                      <div className="workspace__support-preview">
                        <ChatMarkdown content={viewerDraft} />
                      </div>
                    </div>
                  ) : (
                    <textarea
                      className="admin-cell-editor__viewer-textarea"
                      readOnly={viewer.kind === "repo"}
                      value={viewerDraft}
                      onChange={(ev) => setViewerDraft(ev.target.value)}
                      rows={24}
                      spellCheck={false}
                      aria-label="Contenido Markdown"
                    />
                  )}
                </div>
              </>
            ) : (
              <textarea
                className="admin-cell-editor__viewer-textarea"
                readOnly={viewer.kind === "repo"}
                value={viewerDraft}
                onChange={(ev) => setViewerDraft(ev.target.value)}
                rows={24}
              />
            )}
            <div className="admin-cell-editor__modal-actions admin-cell-editor__viewer-actions">
              <button type="button" className="btn" onClick={() => setViewer(null)}>
                Cerrar
              </button>
              {viewer.kind === "support" && (
                <button
                  type="button"
                  className="btn primary"
                  disabled={viewerSaving}
                  onClick={() => void saveSupportViewer()}
                >
                  {viewerSaving ? "Guardando…" : "Guardar y reindexar"}
                </button>
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
