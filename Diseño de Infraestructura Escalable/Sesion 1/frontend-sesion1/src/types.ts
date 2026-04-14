export type GitConnectionMode = "LOCAL" | "HTTPS_PUBLIC" | "HTTPS_AUTH";

export interface GitConnectRequest {
  mode: GitConnectionMode;
  repositoryUrl?: string;
  username?: string;
  token?: string;
  localPath?: string;
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

/** Respuesta de DELETE /vector/index */
export interface VectorClearResponse {
  namespace: string;
  cleared: boolean;
}

/** Eventos NDJSON de POST /vector/ingest/stream */
export type IngestProgressPhase = "START" | "FILE" | "PROGRESS" | "DONE" | "ERROR";

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

export interface TagsResponse {
  tags: string[];
}

/** Documentos de soporte (Markdown) gestionados en el cliente; el backend los persistirá después. */
export interface SupportDocument {
  id: string;
  name: string;
  content: string;
  updatedAt: number;
}
