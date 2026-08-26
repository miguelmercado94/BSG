export type GitConnectionMode = "LOCAL" | "HTTPS_PUBLIC" | "HTTPS_AUTH";

export interface GitConnectRequest {
  mode: GitConnectionMode;
  repositoryUrl?: string;
  username?: string;
  token?: string;
  localPath?: string;
  /** Alinear con el namespace del repo de célula (índice compartido; no re-ingesta en soporte). */
  vectorNamespace?: string;
}

export interface FolderStructureDto {
  folder: string;
  archivos: string[];
  folders: FolderStructureDto[];
}

export interface ConnectResponse {
  usuario: string;
  connected: boolean;
  repositoryRoot: string | null;
  directory: FolderStructureDto | null;
}

export interface FileContentResponse {
  path: string;
  content: string;
  encoding: string;
}

export interface VectorIngestResponse {
  filesProcessed: number;
  chunksIndexed: number;
  skipped: string[];
  namespace: string;
}

/** POST /vector/work-area/s3-borrador-promote */
export interface WorkAreaS3PromoteResponse extends VectorIngestResponse {
  workareaBucket: string;
  workareaObjectKey: string;
}

/** Respuesta de DELETE /vector/index */
export interface VectorClearResponse {
  namespace: string;
  cleared: boolean;
}

/** Eventos NDJSON de POST /vector/ingest/stream y POST /admin/cells/{id}/repos/stream */
export type IngestProgressPhase =
  | "START"
  | "FILE"
  | "PROGRESS"
  | "DONE"
  | "ERROR"
  | "CELL_REPO_READY";

export interface IngestProgressEvent {
  phase: IngestProgressPhase;
  totalFiles?: number;
  filesProcessed?: number;
  chunksIndexed?: number;
  currentFile?: string;
  /** Estado intermedio (p. ej. llamada a Ollama) */
  detail?: string;
  namespace?: string;
  skipped?: string[];
  error?: string;
  /** Metadatos finales en admin (repos/stream) */
  cellRepoId?: string;
  displayName?: string;
  linkedWithoutReindex?: boolean;
}

export interface VectorChatResponse {
  answer: string;
  sources: string[];
}

/** Turno persistido en Firestore (GET /vector/chat/history). El id de conversación es el usuario (X-DocViz-User). */
export interface ChatHistoryEntry {
  id: string;
  question: string;
  answer: string;
  sources: string[];
  repoLabel: string;
  createdAt: string | null;
}

/**
 * Copia sugerida por el LLM (p. ej. A_v1.java frente a A.java). El modelo no escribe en disco:
 * devuelve JSON; el front muestra diff y, al pulsar «Mantener», se podrá indexar vía API.
 */
export type WorkAreaDiffLineKind = "context" | "added" | "removed";

export interface WorkAreaDiffLine {
  kind: WorkAreaDiffLineKind;
  /** Contenido de la línea (sin \\n final). */
  text: string;
}

/** Sustitución por rango de líneas en el archivo base (1-based, inclusive). Opcional en respuestas del backend. */
export interface WorkAreaLineEdit {
  startLine: number;
  endLine: number;
  replacement?: string;
}

/** Hunk anclado por contexto (respuesta del modelo o trazas; el backend suele limpiar tras enriquecer). */
export interface WorkAreaChangeBlock {
  id?: string;
  type: "replace" | "insert" | "delete" | "create_file";
  context_before?: string[];
  original?: string[];
  replacement?: string[];
  context_after?: string[];
  path?: string;
  content?: string[];
}

export interface WorkAreaFileProposal {
  id: string;
  fileName: string;
  /** Sin punto, p. ej. "java", "md". */
  extension: string;
  /** Borrador tipo merge (marcadores &lt;&lt;&lt;&lt;&lt;&lt;&lt;) o vacío tras aceptar. */
  content: string;
  /** Archivo base en el repo indexado (p. ej. src/main/java/a/A.java). */
  sourcePath?: string;
  /** Si el modelo envía rangos antes del enriquecimiento (el backend suele limpiar el campo). */
  lineEdits?: WorkAreaLineEdit[];
  /** Hunks por contexto (preferido frente a reescribir el archivo entero). */
  changeBlocks?: WorkAreaChangeBlock[];
  /** Borrador en disco: `ruta/al/archivo_vN.ext.txt` (legado; el flujo nuevo es solo JSON + memoria). */
  draftRelativePath?: string;
  /** Misma N que en `archivo_vN.ext` (necesaria para aplicar sin .txt). */
  draftVersion?: number;
  /** Tras POST /vector/work-area/draft/accept — ruta del `*_vN.ext` sin .txt */
  acceptedRelativePath?: string;
  /** Tras indexar el borrador aceptado en el vector store (misma sesión UI). */
  vectorIndexed?: boolean;
  /** Fragmentos indexados en la última operación de indexación (opcional). */
  lastIndexedChunks?: number;
  /** GET presignado (listado S3) para cargar el borrador si aún no hay `content` en memoria. */
  s3PresignedUrl?: string;
  /** Bucket y clave en S3 (listados solo desde objetos reales). */
  s3Bucket?: string;
  s3ObjectKey?: string;
  /** Fila del GET /s3-artifacts: solo vista previa vía URL presignada (sin aceptar/indexar en el clon). */
  artifactViewOnly?: boolean;
  /**
   * Líneas para el visor (verde / rojo / gris). Si falta, se muestra `content` como vista previa plana
   * hasta que el backend o un paso intermedio rellene el diff.
   */
  diffLines?: WorkAreaDiffLine[];
}

/** Contenedor típico si el LLM devuelve un JSON con varias copias sugeridas. */
export interface WorkAreaProposalPayload {
  proposals: WorkAreaFileProposal[];
}

/** Respuesta de POST /vector/chat/rag-turn. */
export interface RagChatTurnResponse {
  answer: string;
  sources: string[];
  proposals?: WorkAreaFileProposal[];
}

/** Referencia web asociada a un tag (GET /tags → toolsByTag). */
export interface TagToolRefDto {
  id: string;
  title: string;
  url: string;
  hint?: string;
}

export interface TagsResponse {
  tags: string[];
  toolsByTag?: Record<string, TagToolRefDto[]>;
}

/** Documentos de soporte (Markdown): cliente + opcionalmente S3/pgvector si el API está habilitado. */
export interface SupportDocument {
  id: string;
  name: string;
  content: string;
  updatedAt: number;
  /** Nombre relativo al prefijo S3 (DELETE /support/markdown?fileName=…). */
  storageFileName?: string;
  /** URL presignada para cargar el Markdown sin GET /support/markdown/object. */
  s3Url?: string;
  /** @deprecated usar storageFileName */
  objectKey?: string;
}

/** Respuesta POST /support/markdown */
export interface SupportMarkdownUploadResponse {
  bucket: string;
  objectKey: string;
  /** Nombre relativo al prefijo S3 (para DELETE sin la clave completa). */
  fileName?: string;
  vectorSource: string;
  namespace: string;
  chunksIndexed: number;
}

/** UI del panel de soporte durante POST /support/markdown */
export type SupportUploadUiState =
  | { kind: "idle" }
  | { kind: "busy"; phase: "s3" | "embedding" }
  | { kind: "done"; bucket: string; objectKey: string; chunksIndexed: number }
  | { kind: "local_only" }
  | { kind: "error"; message: string };

/** Dominio: célula (área) configurada por el administrador. */
export interface CellResponse {
  id: string;
  name: string;
  description: string | null;
  createdAt: string | null;
  createdBy: string | null;
}

export interface DeleteImpactResponse {
  taskCount: number;
}

export interface CellRepoResponse {
  id: string;
  cellId: string | null;
  displayName: string;
  repositoryUrl: string;
  connectionMode: GitConnectionMode;
  gitUsername: string | null;
  hasCredential: boolean;
  localPath: string | null;
  tagsCsv: string | null;
  vectorNamespace: string | null;
  active: boolean;
  createdAt: string | null;
  updatedAt: string | null;
  lastIngestAt: string | null;
  lastIngestFiles: number | null;
  lastIngestChunks: number | null;
  lastIngestSkipped: string[] | null;
  linkedWithoutReindex?: boolean;
  indexado?: boolean;
  ramaPrincipal?: string;
  filesPath?: string[];
  folderPath?: string[];
}

export interface PendingIndexBeginResponse {
  linkedWithoutReindex: boolean;
  repo: CellRepoResponse;
}

export interface SinglePathIngestResultDto {
  indexed: boolean;
  skipped: boolean;
  path: string;
  chunksIndexed: number;
  skipReason: string | null;
  errorMessage: string | null;
}

export interface CellRepoUrlHint {
  displayName: string;
  vectorNamespace: string;
  reusedFromExisting: boolean;
  defaultBranch?: string | null;
}

export interface TaskResponse {
  id: string;
  userId: string;
  huCode: string;
  cellRepoId: string;
  enunciado: string;
  status: string;
  createdAt: string | null;
  continuedAt: string | null;
  chatConversationId?: string | null;
}

export interface TaskCreateRequest {
  huCode: string;
  cellRepoId: string;
  cellId: string;
  enunciado: string;
}

export interface TaskContinueResponse {
  taskId: string;
  huCode: string;
  cellRepoId: string;
  gitConnect: GitConnectRequest;
  initialChatPrompt: string;
  vectorNamespaceHint: string;
  cellName?: string | null;
  chatConversationId?: string | null;
}

export interface RestoredWorkAreaProposal {
  id: string;
  fileName: string;
  extension: string;
  content: string;
  draftRelativePath?: string | null;
  acceptedRelativePath?: string | null;
}

export interface TaskArtifactRestoreResponse {
  borradoresRestored: string[];
  workareaRestored: string[];
  proposals: RestoredWorkAreaProposal[];
}

export interface SupportMarkdownObjectDto {
  bucket: string;
  objectKey: string;
  fileName: string;
  url: string;
  displayLabel?: string | null;
}

export interface WorkAreaS3ObjectDto {
  bucket: string;
  objectKey: string;
  fileName: string;
  url: string;
}

export interface CellRequestBody {
  code?: string;
  name: string;
  description?: string;
}

export interface CellRepoRequestBody {
  /** Opcional: el backend lo calcula desde la URL si se omite o va vacío. */
  displayName?: string;
  repositoryUrl: string;
  connectionMode: GitConnectionMode;
  gitUsername?: string;
  credentialPlain?: string;
  localPath?: string;
  tagsCsv?: string;
  vectorNamespace?: string;
}
