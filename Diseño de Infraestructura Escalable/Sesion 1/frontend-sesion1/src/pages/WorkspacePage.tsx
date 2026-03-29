import { FormEvent, useEffect, useState } from "react";
import { Link, useLocation, useNavigate } from "react-router-dom";
import { fetchFileContent, fetchTags, vectorChat, vectorIngest } from "../api/client";
import type { ConnectResponse, FolderStructureDto } from "../types";
import { FolderTree } from "../components/FolderTree";

type LocationState = { connect?: ConnectResponse };

export function WorkspacePage() {
  const navigate = useNavigate();
  const location = useLocation();
  const state = location.state as LocationState | undefined;
  const [connect] = useState<ConnectResponse | null>(state?.connect ?? null);

  const [tags, setTags] = useState<string[]>([]);
  const [tagsErr, setTagsErr] = useState<string | null>(null);

  const [selectedPath, setSelectedPath] = useState<string | null>(null);
  const [fileContent, setFileContent] = useState<string | null>(null);
  const [fileErr, setFileErr] = useState<string | null>(null);

  const [ingestRes, setIngestRes] = useState<string | null>(null);
  const [ingestLoading, setIngestLoading] = useState(false);

  const [question, setQuestion] = useState("");
  const [chatAns, setChatAns] = useState<string | null>(null);
  const [chatSources, setChatSources] = useState<string[]>([]);
  const [chatErr, setChatErr] = useState<string | null>(null);
  const [chatLoading, setChatLoading] = useState(false);

  useEffect(() => {
    if (!connect?.connected) {
      navigate("/", { replace: true });
    }
  }, [connect, navigate]);

  useEffect(() => {
    let cancelled = false;
    (async () => {
      try {
        const t = await fetchTags();
        if (!cancelled) {
          setTags(t.tags);
          setTagsErr(null);
        }
      } catch (e) {
        if (!cancelled) {
          setTagsErr(e instanceof Error ? e.message : String(e));
        }
      }
    })();
    return () => {
      cancelled = true;
    };
  }, []);

  async function onSelectFile(rel: string) {
    setSelectedPath(rel);
    setFileErr(null);
    setFileContent(null);
    try {
      const r = await fetchFileContent(rel);
      setFileContent(r.content);
    } catch (e) {
      setFileErr(e instanceof Error ? e.message : String(e));
    }
  }

  async function onIngest() {
    setIngestRes(null);
    setIngestLoading(true);
    try {
      const r = await vectorIngest();
      setIngestRes(
        `Archivos: ${r.filesProcessed}, chunks: ${r.chunksIndexed}, namespace: ${r.namespace}` +
          (r.skipped?.length ? ` · omitidos: ${r.skipped.join(", ")}` : ""),
      );
    } catch (e) {
      setIngestRes(e instanceof Error ? e.message : String(e));
    } finally {
      setIngestLoading(false);
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
        <p>No hay datos de repositorio. <Link to="/">Volver a conectar</Link></p>
      </div>
    );
  }

  const dir: FolderStructureDto = connect.directory;

  return (
    <div className="page workspace">
      <header className="workspace__bar">
        <div>
          <strong>DocViz</strong>
          <span className="muted"> · {connect.usuario}</span>
          {connect.repositoryRoot && (
            <span className="muted"> · {connect.repositoryRoot}</span>
          )}
        </div>
        <Link to="/" className="btn ghost">
          Otra conexión
        </Link>
      </header>

      <div className="workspace__grid">
        <aside className="panel">
          <h2>Árbol</h2>
          <FolderTree root={dir} onSelectFile={onSelectFile} selectedPath={selectedPath} />
        </aside>

        <section className="panel">
          <h2>Archivo</h2>
          {selectedPath && <div className="path">{selectedPath}</div>}
          {fileErr && <p className="error">{fileErr}</p>}
          {fileContent !== null && (
            <pre className="file-preview">{fileContent}</pre>
          )}
        </section>

        <aside className="panel tags">
          <h2>Tags (demo)</h2>
          {tagsErr && <p className="error">{tagsErr}</p>}
          <ul className="tag-list">
            {tags.map((t) => (
              <li key={t}>{t}</li>
            ))}
          </ul>

          <h2 className="mt">Vector</h2>
          <button type="button" className="btn primary" onClick={onIngest} disabled={ingestLoading}>
            {ingestLoading ? "Indexando…" : "Ingestar en Pinecone"}
          </button>
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
                <div className="small muted">
                  Fuentes: {chatSources.join(" · ")}
                </div>
              )}
            </div>
          )}
        </aside>
      </div>

      <p className="muted small workspace__hint">
        Si recargas la página, la sesión del servidor puede perderse: vuelve a conectar el repositorio.
      </p>
    </div>
  );
}
