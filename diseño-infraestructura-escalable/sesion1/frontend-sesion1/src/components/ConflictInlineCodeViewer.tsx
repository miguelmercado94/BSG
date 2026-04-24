import { forwardRef, useEffect, useImperativeHandle, useMemo, useState } from "react";
import { PrismLight as SyntaxHighlighter } from "react-syntax-highlighter";
import java from "react-syntax-highlighter/dist/esm/languages/prism/java";
import json from "react-syntax-highlighter/dist/esm/languages/prism/json";
import tsx from "react-syntax-highlighter/dist/esm/languages/prism/tsx";
import typescript from "react-syntax-highlighter/dist/esm/languages/prism/typescript";
import { vscDarkPlus } from "react-syntax-highlighter/dist/esm/styles/prism";

import {
  type DocumentSegment,
  parseGitConflictDocument,
} from "../lib/parseGitConflictMarkers";

SyntaxHighlighter.registerLanguage("java", java);
SyntaxHighlighter.registerLanguage("json", json);
SyntaxHighlighter.registerLanguage("tsx", tsx);
SyntaxHighlighter.registerLanguage("typescript", typescript);

export type ConflictResolution = "pending" | "accepted" | "rejected";

export type ConflictInlineCodeViewerHandle = {
  /** Texto resultante según aceptar/rechazar bloques (o el texto original si no hay conflictos parseables). */
  getResolvedText: () => string;
  /** Hay bloques de conflicto sin elegir original vs sugerido. */
  hasPendingConflicts: () => boolean;
};

function detectLanguage(fileName: string | undefined): string {
  if (!fileName) return "java";
  const lower = fileName.toLowerCase();
  if (lower.endsWith(".json")) return "json";
  if (lower.endsWith(".tsx")) return "tsx";
  if (lower.endsWith(".ts")) return "typescript";
  if (lower.endsWith(".java")) return "java";
  return "java";
}

type BlockProps = {
  code: string;
  language: string;
  startingLineNumber: number;
  variant: "neutral" | "original" | "suggested";
};

function HighlightedBlock({ code, language, startingLineNumber, variant }: BlockProps) {
  if (code.length === 0) {
    return null;
  }
  const band =
    variant === "original"
      ? "border-l-4 border-red-500/90 bg-red-950/35"
      : variant === "suggested"
        ? "border-l-4 border-emerald-500/85 bg-emerald-950/30"
        : "";

  return (
    <div className={band}>
      <SyntaxHighlighter
        language={language}
        style={vscDarkPlus}
        startingLineNumber={startingLineNumber}
        showLineNumbers
        lineNumberStyle={{
          minWidth: "2.75rem",
          paddingRight: "0.65rem",
          color: "#6b7280",
          userSelect: "none",
          borderRight: "1px solid rgba(255,255,255,0.06)",
        }}
        customStyle={{
          margin: 0,
          padding: "0.45rem 0.65rem 0.55rem 0.5rem",
          background: "transparent",
          fontSize: "0.8125rem",
          lineHeight: 1.55,
        }}
        PreTag="div"
        codeTagProps={{
          style: {
            fontFamily:
              "ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, 'Liberation Mono', monospace",
          },
        }}
      >
        {code}
      </SyntaxHighlighter>
    </div>
  );
}

type ToolbarProps = {
  onAccept: () => void;
  onReject: () => void;
  onCompare: () => void;
};

function ConflictFloatingToolbar({ onAccept, onReject, onCompare }: ToolbarProps) {
  return (
    <div className="pointer-events-auto absolute right-2 top-1 z-20 flex gap-1 rounded-md border border-white/15 bg-[#2d2d2d]/95 px-1 py-0.5 text-[0.72rem] shadow-lg backdrop-blur-sm">
      <button
        type="button"
        className="rounded px-2 py-0.5 font-medium text-emerald-200 transition hover:bg-emerald-600/25"
        onClick={onAccept}
      >
        Aceptar
      </button>
      <button
        type="button"
        className="rounded px-2 py-0.5 font-medium text-red-200/95 transition hover:bg-red-600/25"
        onClick={onReject}
      >
        Rechazar
      </button>
      <button
        type="button"
        className="rounded px-2 py-0.5 font-medium text-sky-200/95 transition hover:bg-sky-600/25"
        onClick={onCompare}
      >
        Comparar
      </button>
    </div>
  );
}

type CompareModalProps = {
  original: string;
  suggested: string;
  language: string;
  onClose: () => void;
};

function CompareModal({ original, suggested, language, onClose }: CompareModalProps) {
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") onClose();
    };
    document.addEventListener("keydown", onKey);
    return () => document.removeEventListener("keydown", onKey);
  }, [onClose]);

  return (
    <div
      className="fixed inset-0 z-[100] flex items-center justify-center bg-black/65 p-4 backdrop-blur-[2px]"
      role="dialog"
      aria-modal="true"
      aria-labelledby="conflict-compare-title"
      onClick={(e) => {
        if (e.target === e.currentTarget) onClose();
      }}
    >
      <div className="flex max-h-[min(90vh,920px)] w-full max-w-6xl flex-col overflow-hidden rounded-lg border border-white/15 bg-[#1e1e1e] shadow-2xl">
        <div className="flex shrink-0 items-center justify-between border-b border-white/10 px-3 py-2">
          <h2 id="conflict-compare-title" className="m-0 text-sm font-semibold text-neutral-200">
            Comparar bloque
          </h2>
          <button
            type="button"
            className="rounded px-2 py-1 text-xs text-neutral-400 hover:bg-white/10 hover:text-white"
            onClick={onClose}
          >
            Cerrar
          </button>
        </div>
        <div className="grid min-h-0 flex-1 grid-cols-1 gap-px bg-white/10 md:grid-cols-2">
          <div className="flex min-h-0 flex-col bg-[#1e1e1e]">
            <div className="shrink-0 border-b border-red-500/35 bg-red-950/40 px-2 py-1 text-[0.65rem] font-semibold uppercase tracking-wide text-red-200/90">
              Original (CURRENT)
            </div>
            <div className="min-h-0 flex-1 overflow-auto">
              <SyntaxHighlighter
                language={language}
                style={vscDarkPlus}
                showLineNumbers
                customStyle={{
                  margin: 0,
                  padding: "0.5rem 0.65rem",
                  background: "transparent",
                  fontSize: "0.78rem",
                  minHeight: "12rem",
                }}
                PreTag="div"
              >
                {original.length ? original : " "}
              </SyntaxHighlighter>
            </div>
          </div>
          <div className="flex min-h-0 flex-col bg-[#1e1e1e]">
            <div className="shrink-0 border-b border-emerald-500/35 bg-emerald-950/35 px-2 py-1 text-[0.65rem] font-semibold uppercase tracking-wide text-emerald-200/90">
              Sugerencia (SUGGESTED)
            </div>
            <div className="min-h-0 flex-1 overflow-auto">
              <SyntaxHighlighter
                language={language}
                style={vscDarkPlus}
                showLineNumbers
                customStyle={{
                  margin: 0,
                  padding: "0.5rem 0.65rem",
                  background: "transparent",
                  fontSize: "0.78rem",
                  minHeight: "12rem",
                }}
                PreTag="div"
              >
                {suggested.length ? suggested : " "}
              </SyntaxHighlighter>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

function renderSegmentsToString(segments: DocumentSegment[], resolution: Record<number, ConflictResolution>): string {
  const parts: string[] = [];
  for (const seg of segments) {
    if (seg.type === "normal") {
      parts.push(...seg.lines);
    } else {
      const res = resolution[seg.index] ?? "pending";
      if (res === "accepted") {
        parts.push(...seg.suggested);
      } else if (res === "rejected") {
        parts.push(...seg.original);
      } else {
        parts.push(...seg.original, ...seg.suggested);
      }
    }
  }
  return parts.join("\n");
}

export type ConflictInlineCodeViewerProps = {
  fileContent: string;
  /** Para inferir lenguaje (java, json, tsx…) */
  fileName?: string;
  className?: string;
};

/**
 * Visor continuo con resaltado Prism; bloques de conflicto con estilo tipo Cursor y barra de acciones.
 */
export const ConflictInlineCodeViewer = forwardRef<ConflictInlineCodeViewerHandle, ConflictInlineCodeViewerProps>(
  function ConflictInlineCodeViewer({ fileContent, fileName, className = "" }, ref) {
  const parsed = useMemo(() => parseGitConflictDocument(fileContent), [fileContent]);
  const language = useMemo(() => detectLanguage(fileName), [fileName]);

  const [resolution, setResolution] = useState<Record<number, ConflictResolution>>({});
  const [comparing, setComparing] = useState<number | null>(null);

  useImperativeHandle(
    ref,
    () => ({
      getResolvedText: () => {
        if (!parsed.ok) return fileContent;
        return renderSegmentsToString(parsed.segments, resolution);
      },
      hasPendingConflicts: () => {
        if (!parsed.ok) return false;
        return parsed.segments.some(
          (s) => s.type === "conflict" && (resolution[s.index] ?? "pending") === "pending",
        );
      },
    }),
    [fileContent, parsed, resolution],
  );

  if (!parsed.ok) {
    return (
      <pre
        className={`file-preview m-0 overflow-auto whitespace-pre-wrap break-words ${className}`}
        spellCheck={false}
      >
        {fileContent}
      </pre>
    );
  }

  const { segments } = parsed;
  let lineCounter = 1;

  const updateResolution = (index: number, next: ConflictResolution) => {
    setResolution((prev) => ({ ...prev, [index]: next }));
  };

  return (
    <>
      <div
        className={`relative overflow-auto rounded-md border border-white/10 bg-[#1e1e1e] font-mono text-sm text-[#d4d4d4] ${className}`}
      >
        {segments.map((seg, si) => {
          if (seg.type === "normal") {
            const code = seg.lines.join("\n");
            const start = lineCounter;
            lineCounter += seg.lines.length;
            return (
              <HighlightedBlock
                key={`n-${si}`}
                code={code}
                language={language}
                startingLineNumber={start}
                variant="neutral"
              />
            );
          }

          const res = resolution[seg.index] ?? "pending";
          const orig = seg.original.join("\n");
          const sugg = seg.suggested.join("\n");

          if (res === "accepted") {
            const code = sugg;
            const start = lineCounter;
            lineCounter += seg.suggested.length;
            return (
              <HighlightedBlock
                key={`c-acc-${si}`}
                code={code}
                language={language}
                startingLineNumber={start}
                variant="neutral"
              />
            );
          }

          if (res === "rejected") {
            const code = orig;
            const start = lineCounter;
            lineCounter += seg.original.length;
            return (
              <HighlightedBlock
                key={`c-rej-${si}`}
                code={code}
                language={language}
                startingLineNumber={start}
                variant="neutral"
              />
            );
          }

          const oLines = seg.original.length;
          const sLines = seg.suggested.length;
          const startOrig = lineCounter;
          lineCounter += oLines + sLines;

          return (
            <div key={`c-${si}`} className="relative border-t border-white/5 pt-7">
              <ConflictFloatingToolbar
                onAccept={() => updateResolution(seg.index, "accepted")}
                onReject={() => updateResolution(seg.index, "rejected")}
                onCompare={() => setComparing(seg.index)}
              />
              <div className="rounded-md border border-white/5">
                <div className="border-b border-white/5 px-2 py-0.5 text-[0.65rem] font-medium uppercase tracking-wide text-red-200/80">
                  Original
                </div>
                <HighlightedBlock
                  code={orig}
                  language={language}
                  startingLineNumber={startOrig}
                  variant="original"
                />
                <div className="border-b border-t border-white/5 bg-black/20 px-2 py-0.5 text-[0.65rem] font-medium uppercase tracking-wide text-emerald-200/85">
                  Sugerencia
                </div>
                <HighlightedBlock
                  code={sugg}
                  language={language}
                  startingLineNumber={startOrig + oLines}
                  variant="suggested"
                />
              </div>
            </div>
          );
        })}
      </div>

      {comparing !== null &&
        (() => {
          const c = segments.find((s) => s.type === "conflict" && s.index === comparing);
          if (!c || c.type !== "conflict") return null;
          return (
            <CompareModal
              original={c.original.join("\n")}
              suggested={c.suggested.join("\n")}
              language={language}
              onClose={() => setComparing(null)}
            />
          );
        })()}
    </>
  );
  },
);

ConflictInlineCodeViewer.displayName = "ConflictInlineCodeViewer";

export function buildResolvedPreviewText(
  fileContent: string,
  resolution: Record<number, ConflictResolution>,
): string | null {
  const parsed = parseGitConflictDocument(fileContent);
  if (!parsed.ok) return null;
  return renderSegmentsToString(parsed.segments, resolution);
}
