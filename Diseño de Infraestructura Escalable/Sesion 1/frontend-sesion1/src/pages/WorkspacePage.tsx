import { FormEvent, useEffect, useRef, useState } from "react";

import { Link, useLocation, useNavigate } from "react-router-dom";

import {
  clearUserId,
  fetchChatHistory,
  fetchFileContent,
  logoutSession,
  vectorChat,
  vectorClearIndex,
  vectorIngestStream,
} from "../api/client";

import type { ChatHistoryEntry, ConnectResponse, FolderStructureDto } from "../types";

import { ChatMarkdown } from "../components/ChatMarkdown";
import { FolderTree } from "../components/FolderTree";
import { SupportPanel } from "../components/SupportPanel";
import { useSupportDocuments } from "../hooks/useSupportDocuments";



type LocationState = { connect?: ConnectResponse; selectedTags?: string[] };

type FileViewSource = "repo" | "support";



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

    detail: string | null;

    /** stream = NDJSON con progreso por archivo; sync reservado si en el futuro se usa ingesta sin stream */
    mode: "sync" | "stream";

  } | null>(null);



  const [question, setQuestion] = useState("");

  const [chatTurns, setChatTurns] = useState<ChatHistoryEntry[]>([]);

  const [chatHistoryErr, setChatHistoryErr] = useState<string | null>(null);

  const [chatErr, setChatErr] = useState<string | null>(null);

  const [chatLoading, setChatLoading] = useState(false);

  const [logoutLoading, setLogoutLoading] = useState(false);

  const [logoutErr, setLogoutErr] = useState<string | null>(null);

  const [ingestRetry, setIngestRetry] = useState(0);

  const [clearLoading, setClearLoading] = useState(false);

  const [clearErr, setClearErr] = useState<string | null>(null);



  const [fileViewSource, setFileViewSource] = useState<FileViewSource>("repo");

  const [selectedSupportId, setSelectedSupportId] = useState<string | null>(null);

  const [supportEditing, setSupportEditing] = useState(false);

  const [supportDraft, setSupportDraft] = useState("");



  const filePreviewLru = useRef<Map<string, string>>(new Map());



  const { docs: supportDocs, add: addSupportDoc, update: updateSupportDoc, remove: removeSupportDoc } =

    useSupportDocuments(connect?.usuario ?? "");



  useEffect(() => {

    if (!connect?.connected) {

      navigate("/", { replace: true });

    }

  }, [connect, navigate]);



  useEffect(() => {

    if (selectedSupportId && !supportDocs.some((d) => d.id === selectedSupportId)) {

      setSelectedSupportId(null);

      setFileViewSource("repo");

      setSupportEditing(false);

    }

  }, [supportDocs, selectedSupportId]);



  /** Ingesta automática al mostrar el contexto maestro (una vez por carga del workspace). */

  useEffect(() => {

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



  /** Historial RAG desde Firestore (mismo usuario que X-DocViz-User). */
  useEffect(() => {
    if (!ingestComplete) return;
    let cancelled = false;
    (async () => {
      try {
        setChatHistoryErr(null);
        const rows = await fetchChatHistory(50);
        if (!cancelled) setChatTurns(rows);
      } catch (e) {
        if (!cancelled) {
          setChatHistoryErr(e instanceof Error ? e.message : String(e));
        }
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [ingestComplete, ingestRetry]);



  async function onClearVectorIndex() {
    setClearErr(null);
    setClearLoading(true);
    try {
      await vectorClearIndex();
      setIngestRetry((n) => n + 1);
    } catch (e) {
      setClearErr(e instanceof Error ? e.message : String(e));
    } finally {
      setClearLoading(false);
    }
  }



  async function onSelectFile(rel: string) {

    setFileViewSource("repo");

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

    setSelectedSupportId(id);

    setSelectedPath(null);

    setFileContent(null);

    setFileErr(null);

    setSupportEditing(false);

    const doc = supportDocs.find((d) => d.id === id);

    setSupportDraft(doc?.content ?? "");

  }



  function handleSupportUpload(fileName: string, content: string) {

    const id = addSupportDoc(fileName, content);

    setFileViewSource("support");

    setSelectedSupportId(id);

    setSelectedPath(null);

    setFileContent(null);

    setFileErr(null);

    setSupportEditing(false);

    setSupportDraft(content);

  }



  function handleSupportDelete(id: string) {

    removeSupportDoc(id);

    if (selectedSupportId === id) {

      setSelectedSupportId(null);

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

    const q = question.trim();

    if (!q) return;

    setChatLoading(true);

    try {

      const res = await vectorChat(q);

      setQuestion("");

      const localTurn = (id: string): ChatHistoryEntry => ({

        id,

        question: q,

        answer: res.answer,

        sources: res.sources ?? [],

        repoLabel: "",

        createdAt: new Date().toISOString(),

      });

      try {

        const rows = await fetchChatHistory(50);

        setChatHistoryErr(null);

        if (rows.length > 0) {

          setChatTurns(rows);

        } else {

          // Sin Firestore o aún sin documentos: la UI solo leía historial vacío y ocultaba la respuesta del POST.

          setChatTurns((prev) => [...prev, localTurn(`local-${Date.now()}`)]);

        }

      } catch (histErr) {

        setChatHistoryErr(histErr instanceof Error ? histErr.message : String(histErr));

        setChatTurns((prev) => [...prev, localTurn(`local-${Date.now()}`)]);

      }

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



  const selectedSupportDoc =

    selectedSupportId != null ? supportDocs.find((d) => d.id === selectedSupportId) : undefined;



  const headerFileLabel =

    fileViewSource === "support" && selectedSupportDoc

      ? selectedSupportDoc.name

      : selectedPath?.trim()

        ? basenameRel(selectedPath)

        : null;



  const headerFileTitle =

    fileViewSource === "support" && selectedSupportDoc

      ? `Soporte · ${selectedSupportDoc.name}`

      : selectedPath?.trim()

        ? selectedPath

        : undefined;



  return (

    <div className="page page--workspace workspace">

      <header className="workspace__bar workspace__bar--with-actions workspace__bar--ingest-fullwidth">

        <div className="workspace__bar-top">

          <div className="workspace__bar-col workspace__bar-row--header-main workspace__bar-col--main workspace__bar-col--header-text">

            <span className="workspace__header-user">{connect.usuario}</span>

            <span

              className={
                headerFileLabel
                  ? "workspace__header-file muted"
                  : "workspace__header-session-hint muted"
              }

              title={headerFileTitle}

            >

              {headerFileLabel
                ? headerFileLabel
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

        </div>

        <div className="workspace__bar-ingest" aria-live="polite">

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

              <div className="ingest-complete__row">

                <span className="ingest-complete__title">Índice listo</span>

                <span className="ingest-complete__stats ingest-complete__stats--bar small">

                  <strong>{ingestResult.filesProcessed}</strong> arch ·{" "}

                  <strong>{ingestResult.chunksIndexed}</strong> chunks ·{" "}

                  <code className="ingest-complete__ns">{ingestResult.namespace}</code>

                </span>

                <button

                  type="button"

                  className="btn secondary btn--compact"

                  disabled={clearLoading || ingestLoading}

                  onClick={() => void onClearVectorIndex()}

                >

                  {clearLoading ? "Vaciando…" : "Vaciar índice"}

                </button>

              </div>

              {clearErr && (

                <p className="error small workspace__bar-ingest-err" role="alert">

                  {clearErr}

                </p>

              )}

              {ingestResult.skipped.length > 0 && (

                <details className="ingest-skipped-details ingest-skipped-details--bar small">

                  <summary>Omitidos ({ingestResult.skipped.length})</summary>

                  <ul className="ingest-skipped-list">

                    {ingestResult.skipped.map((s, i) => (

                      <li key={`${i}-${s}`}>{s}</li>

                    ))}

                  </ul>

                </details>

              )}

            </div>

          )}

        </div>

      </header>



      <div className="workspace__grid">

        <aside className="panel workspace__panel workspace__panel--sidebar">

          <div className="workspace__sidebar-section workspace__sidebar-section--tree">

            <h2>CONTEXTO MAESTRO</h2>

            <FolderTree root={dir} onSelectFile={onSelectFile} selectedPath={selectedPath} />

          </div>

          <div className="workspace__sidebar-section workspace__sidebar-section--support">

            <h2>SOPORTE</h2>

            <div className="workspace__support-wrap">

              <SupportPanel

                documents={supportDocs}

                selectedId={selectedSupportId}

                onSelect={onSelectSupport}

                onUpload={handleSupportUpload}

                onDelete={handleSupportDelete}

              />

            </div>

          </div>

        </aside>



        <section className="panel workspace__panel workspace__panel--file">

          <h2>{fileViewSource === "support" ? "Soporte" : "Archivo"}</h2>

          {fileViewSource === "repo" && selectedPath && <div className="path">{selectedPath}</div>}

          {fileViewSource === "support" && selectedSupportDoc && (

            <div className="path">

              Soporte · {selectedSupportDoc.name}

              <span className="muted small workspace__path-hint">(local — pendiente de backend)</span>

            </div>

          )}



          <div className="workspace__file-body">

            {fileViewSource === "repo" && fileErr && <p className="error">{fileErr}</p>}

            {fileViewSource === "repo" && fileContent !== null && (

              <pre className="file-preview">{fileContent}</pre>

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

                Sube un .md o elige un soporte en la columna izquierda.

              </div>

            )}

          </div>

        </section>



        <aside className="panel workspace__panel workspace__panel--chat">

          <h2 className="workspace__panel-chat-title">Consulta</h2>

          <div className="workspace__chat-scroll">

          {chatHistoryErr && (

            <p className="error small workspace__chat-scroll-err" role="status">

              Historial: {chatHistoryErr}

            </p>

          )}

          {chatErr && <p className="error workspace__chat-scroll-err">{chatErr}</p>}

          <div className="chat-thread">

            {chatTurns.map((t) => (

              <article key={t.id} className="chat-thread__turn">

                <div className="chat-thread__question">

                  <span className="chat-thread__label">Tú</span>

                  <div className="chat-thread__question-text">{t.question}</div>

                </div>

                <div className="chat-thread__answer">

                  <span className="chat-thread__label">Asistente</span>

                  <ChatMarkdown content={t.answer} />

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

            ))}

          </div>

          {chatLoading && (

            <p className="muted small chat-thread__loading" aria-live="polite">

              Generando respuesta…

            </p>

          )}

          </div>

          <form className="chat-form workspace__chat-composer" onSubmit={onChat}>

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

        </aside>

      </div>

    </div>

  );

}

