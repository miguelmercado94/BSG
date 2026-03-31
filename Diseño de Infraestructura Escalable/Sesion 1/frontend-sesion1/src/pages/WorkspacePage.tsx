import { FormEvent, useEffect, useRef, useState } from "react";

import { Link, useLocation, useNavigate } from "react-router-dom";

import { clearUserId, fetchFileContent, logoutSession, vectorChat, vectorIngestStream } from "../api/client";

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



/** Último segmento de una ruta relativa (nombre de archivo o carpeta). */

function basenameRel(rel: string): string {

  const normalized = rel.replace(/\\/g, "/").replace(/\/+$/, "");

  const i = normalized.lastIndexOf("/");

  return i >= 0 ? normalized.slice(i + 1) : normalized;

}



export function WorkspacePage() {

  const navigate = useNavigate();

  const location = useLocation();

  const state = location.state as LocationState | undefined;

  const [connect] = useState<ConnectResponse | null>(state?.connect ?? null);



  const [selectedPath, setSelectedPath] = useState<string | null>(null);

  const [fileContent, setFileContent] = useState<string | null>(null);

  const [fileErr, setFileErr] = useState<string | null>(null);



  const [ingestComplete, setIngestComplete] = useState(false);

  const [ingestResult, setIngestResult] = useState<{

    filesProcessed: number;

    chunksIndexed: number;

    namespace: string;

    skipped: string[];

  } | null>(null);

  const [ingestErr, setIngestErr] = useState<string | null>(null);

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

  const [logoutLoading, setLogoutLoading] = useState(false);

  const [logoutErr, setLogoutErr] = useState<string | null>(null);



  const filePreviewLru = useRef<Map<string, string>>(new Map());



  useEffect(() => {

    if (!connect?.connected) {

      navigate("/", { replace: true });

    }

  }, [connect, navigate]);



  /** Ingesta automática al mostrar el contexto maestro (una vez por carga del workspace). */

  useEffect(() => {

    if (!connect?.directory) return;

    let cancelled = false;

    setIngestErr(null);

    setIngestResult(null);

    setIngestComplete(false);

    setIngestLoading(true);

    setIngestProgress({ totalFiles: 0, filesProcessed: 0, chunksIndexed: 0, currentFile: null });

    async function runAutoIngest() {

      try {

        const r = await vectorIngestStream((ev) => {

          if (cancelled) return;

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

    };

  }, [connect?.directory]);



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



  async function onLogout() {

    setLogoutErr(null);

    setLogoutLoading(true);

    try {

      await logoutSession();

      clearUserId();

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

    <div className="page page--workspace workspace">

      <header className="workspace__bar workspace__bar--minimal workspace__bar--with-actions">

        <div className="workspace__bar-col workspace__bar-row--header-main">

          <span className="workspace__header-user">{connect.usuario}</span>

          <span

            className={
              selectedPath?.trim()
                ? "workspace__header-file muted"
                : "workspace__header-session-hint muted"
            }

            title={selectedPath?.trim() ? selectedPath : undefined}

          >

            {selectedPath?.trim()
              ? basenameRel(selectedPath)
              : "Si recargas la página, la sesión del servidor puede perderse: vuelve a conectar desde el inicio."}

          </span>

        </div>

        <div className="workspace__header-actions">

          {logoutErr && (

            <p className="error small workspace__logout-error" role="alert">

              {logoutErr}

            </p>

          )}

          <button

            type="button"

            className="btn workspace__logout-btn"

            onClick={onLogout}

            disabled={logoutLoading}

            aria-busy={logoutLoading}

            aria-label={logoutLoading ? "Cerrando sesión" : "Cerrar sesión"}

            title="Cerrar sesión"

          >

            {logoutLoading ? (

              <span className="workspace__logout-spinner" aria-hidden />

            ) : (

              <span className="workspace__logout-btn-icon" aria-hidden>

                <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none">

                  <path

                    d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4M16 17l5-5-5-5M21 12H9"

                    stroke="currentColor"

                    strokeWidth="2"

                    strokeLinecap="round"

                    strokeLinejoin="round"

                  />

                </svg>

              </span>

            )}

          </button>

        </div>

      </header>



      <div className="workspace__grid">

        <aside className="panel workspace__panel workspace__panel--tree">

          <h2>CONTEXTO MAESTRO</h2>

          <FolderTree root={dir} onSelectFile={onSelectFile} selectedPath={selectedPath} />

        </aside>



        <section className="panel workspace__panel workspace__panel--file">

          <h2>Archivo</h2>

          {selectedPath && <div className="path">{selectedPath}</div>}

          {fileErr && <p className="error">{fileErr}</p>}

          {fileContent !== null && <pre className="file-preview">{fileContent}</pre>}

        </section>



        <aside className="panel workspace__panel workspace__panel--chat">

          <h2 className="workspace__panel-chat-title">Consulta</h2>

          {ingestLoading && ingestProgress && (

            <div className="ingest-progress ingest-progress--auto" aria-live="polite">

              <p className="ingest-progress__lead small muted">Indexando el repositorio en Pinecone…</p>

              <div className="ingest-progress__stats">

                {ingestProgress.totalFiles > 0 ? (

                  <>

                    Archivos:{" "}

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

          {ingestErr && (

            <p className="error small mt" role="alert">

              {ingestErr}

            </p>

          )}



          {ingestComplete && ingestResult && (

            <div className="ingest-complete mt" role="status">

              <div className="ingest-complete__title">Índice listo</div>

              <p className="ingest-complete__stats small">

                Archivos: <strong>{ingestResult.filesProcessed}</strong>

                {" · "}

                Chunks: <strong>{ingestResult.chunksIndexed}</strong>

                {" · "}

                <code className="ingest-complete__ns">{ingestResult.namespace}</code>

              </p>

              {ingestResult.skipped.length > 0 && (

                <details className="ingest-skipped-details small">

                  <summary>Archivos omitidos ({ingestResult.skipped.length})</summary>

                  <ul className="ingest-skipped-list">

                    {ingestResult.skipped.map((s, i) => (

                      <li key={`${i}-${s}`}>{s}</li>

                    ))}

                  </ul>

                </details>

              )}

            </div>

          )}



          <form className="chat-form mt" onSubmit={onChat}>

            <label className="field">

              <span>Pregunta (RAG)</span>

              <textarea

                rows={3}

                value={question}

                onChange={(e) => setQuestion(e.target.value)}

                disabled={!ingestComplete}

                placeholder={

                  ingestComplete

                    ? "Pregunta sobre el código indexado…"

                    : ingestLoading

                      ? "Espera a que termine la indexación…"

                      : "Espera a que el índice esté listo…"

                }

              />

            </label>

            <button type="submit" className="btn primary" disabled={!ingestComplete || chatLoading}>

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

    </div>

  );

}

