import { FormEvent, useEffect, useRef, useState } from "react";
import { Link, useLocation, useNavigate } from "react-router-dom";
import { fetchFileContent, vectorChat, vectorIngestStream } from "../api/client";
import type { ConnectResponse, FolderStructureDto } from "../types";
import { FolderTree } from "../components/FolderTree";

type LocationState = { connect?: ConnectResponse; selectedTags?: string[] };

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

export function WorkspacePage() {
  const navigate = useNavigate();
  const location = useLocation();
  const state = location.state as LocationState | undefined;
  const [connect] = useState<ConnectResponse | null>(state?.connect ?? null);
  const [selectedTags] = useState<string[]>(state?.selectedTags ?? []);

  const [selectedPath, setSelectedPath] = useState<string | null>(null);
  const [fileContent, setFileContent] = useState<string | null>(null);
  const [fileErr, setFileErr] = useState<string | null>(null);

  const [ingestRes, setIngestRes] = useState<string | null>(null);
  const [ingestLoading, setIngestLoading] = useState(false);
  const [ingestProgress, setIngestProgress] = useState<{
    totalFiles: number;
    filesProcessed: number;
    chunksIndexed: number;
    currentFile: string | null;
  } | null>(null);

  const [question, setQuestion] = useState("");
  const [chatAns, setChatAns] = useState<string | null>(null);
  const [chatSources, setChatSources] = useState<string[]>([]);
  const [chatErr, setChatErr] = useState<string | null>(null);
  const [chatLoading, setChatLoading] = useState(false);

  const filePreviewLru = useRef<Map<string, string>>(new Map());

  useEffect(() => {
    if (!connect?.connected) {
      navigate("/", { replace: true });
    }
  }, [connect, navigate]);

  async function onSelectFile(rel: string) {
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

  async function onIngest() {
    setIngestRes(null);
    setIngestLoading(true);
    setIngestProgress({ totalFiles: 0, filesProcessed: 0, chunksIndexed: 0, currentFile: null });
    try {
      const r = await vectorIngestStream((ev) => {
        if (ev.phase === "START" && ev.totalFiles != null) {
          setIngestProgress({
            totalFiles: ev.totalFiles,
            filesProcessed: 0,
            chunksIndexed: 0,
            currentFile: null,
          });
        }
        if (ev.phase === "FILE" || ev.phase === "PROGRESS") {
          setIngestProgress((prev) => ({
            totalFiles: ev.totalFiles ?? prev?.totalFiles ?? 0,
            filesProcessed: ev.filesProcessed ?? 0,
            chunksIndexed: ev.chunksIndexed ?? 0,
            currentFile: ev.currentFile ?? null,
          }));
        }
      });
      setIngestRes(
        `Archivos: ${r.filesProcessed}, chunks: ${r.chunksIndexed}, namespace: ${r.namespace}` +
          (r.skipped?.length ? ` · omitidos: ${r.skipped.join(", ")}` : ""),
      );
    } catch (e) {
      setIngestRes(e instanceof Error ? e.message : String(e));
    } finally {
      setIngestLoading(false);
      setIngestProgress(null);
    }
  }

  async function onChat(e: FormEvent) {
    e.preventDefault();
    setChatErr(null);
    setChatAns(null);
    setChatSources([]);
    if (!question.trim()) return;
    setChatLoading(true);
    try {
      const r = await vectorChat(question.trim());
      setChatAns(r.answer);
      setChatSources(r.sources ?? []);
    } catch (err) {
      setChatErr(err instanceof Error ? err.message : String(err));
    } finally {
      setChatLoading(false);
    }
  }

  if (!connect?.directory) {
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

  return (
    <div className="page workspace">
      <header className="workspace__bar workspace__bar--stacked">
        <div className="workspace__bar-row">
          <strong>DocViz</strong>
          <span className="muted"> · {connect.usuario}</span>
        </div>
        <div className="workspace__context-block">
          <div className="workspace__context-label">CONTEXTO MAESTRO</div>
          {selectedTags.length > 0 && (
            <div className="workspace__diamonds" aria-label="Etiquetas seleccionadas">
              {selectedTags.map((t) => (
                <span key={t} className="tag-diamond tag-diamond--readonly">
                  <span className="tag-diamond__label">{t}</span>
                </span>
              ))}
            </div>
          )}
        </div>
        {connect.repositoryRoot && (
          <div className="workspace__repo muted small">{connect.repositoryRoot}</div>
        )}
      </header>

      <div className="workspace__grid">
        <aside className="panel">
          <h2>CONTEXTO MAESTRO</h2>
          <FolderTree root={dir} onSelectFile={onSelectFile} selectedPath={selectedPath} />
        </aside>

        <section className="panel">
          <h2>Archivo</h2>
          {selectedPath && <div className="path">{selectedPath}</div>}
          {fileErr && <p className="error">{fileErr}</p>}
          {fileContent !== null && <pre className="file-preview">{fileContent}</pre>}
        </section>

        <aside className="panel tags">
          <h2>Vector</h2>
          <button type="button" className="btn primary" onClick={onIngest} disabled={ingestLoading}>
            {ingestLoading ? "Indexando…" : "Ingestar en Pinecone"}
          </button>
          {ingestLoading && ingestProgress && (
            <div className="ingest-progress mt" aria-live="polite">
              <div className="ingest-progress__stats">
                {ingestProgress.totalFiles > 0 ? (
                  <>
                    Archivos indexados:{" "}
                    <strong>
                      {ingestProgress.filesProcessed} / {ingestProgress.totalFiles}
                    </strong>
                    <span className="muted"> · Chunks: {ingestProgress.chunksIndexed}</span>
                  </>
                ) : (
                  <span className="muted">Preparando lista de archivos…</span>
                )}
              </div>
              {ingestProgress.currentFile && (
                <div className="ingest-progress__file small muted" title={ingestProgress.currentFile}>
                  {ingestProgress.currentFile}
                </div>
              )}
              <div
                className={
                  "ingest-progress__track" +
                  (ingestProgress.totalFiles === 0 ? " ingest-progress__track--indeterminate" : "")
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
          {ingestRes && <p className="small mt">{ingestRes}</p>}

          <form className="chat-form mt" onSubmit={onChat}>
            <label className="field">
              <span>Pregunta (RAG)</span>
              <textarea
                rows={3}
                value={question}
                onChange={(e) => setQuestion(e.target.value)}
                placeholder="Pregunta sobre el código indexado…"
              />
            </label>
            <button type="submit" className="btn" disabled={chatLoading}>
              {chatLoading ? "Pensando…" : "Preguntar"}
            </button>
          </form>
          {chatErr && <p className="error">{chatErr}</p>}
          {chatAns && (
            <div className="chat-answer">
              <p>{chatAns}</p>
              {chatSources.length > 0 && (
                <div className="small muted">Fuentes: {chatSources.join(" · ")}</div>
              )}
            </div>
          )}
        </aside>
      </div>

      <p className="muted small workspace__hint">
        Si recargas la página, la sesión del servidor puede perderse: vuelve a conectar desde el inicio.
      </p>
    </div>
  );
}
