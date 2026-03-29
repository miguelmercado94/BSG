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

export interface VectorChatResponse {
  answer: string;
  sources: string[];
}

export interface TagsResponse {
  tags: string[];
}
