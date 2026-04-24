import { useCallback, useEffect, useRef, useState } from "react";
import type { MouseEvent as ReactMouseEvent } from "react";

const STORAGE_KEY = "docviz_workspace_cols_v1";
/** Ratio 1fr : 1.4fr : 1fr */
const DEFAULT_PCTS: [number, number, number] = [29.41, 41.18, 29.41];
const MIN_PCT = 14;
export const WORKSPACE_RESIZE_HANDLE_PX = 6;

function loadInitial(): [number, number, number] {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (!raw) return [...DEFAULT_PCTS] as [number, number, number];
    const j = JSON.parse(raw) as unknown;
    if (!Array.isArray(j) || j.length !== 3) return [...DEFAULT_PCTS] as [number, number, number];
    const a = Number(j[0]);
    const b = Number(j[1]);
    const c = Number(j[2]);
    if (![a, b, c].every((x) => Number.isFinite(x) && x > 0)) {
      return [...DEFAULT_PCTS] as [number, number, number];
    }
    const s = a + b + c;
    if (Math.abs(s - 100) > 0.5) {
      return [...DEFAULT_PCTS] as [number, number, number];
    }
    return [a, b, c];
  } catch {
    return [...DEFAULT_PCTS] as [number, number, number];
  }
}

/** Arrastra entre col izquierda y centro; c fijo */
function applyDragLeftRight(start: [number, number, number], dp: number): [number, number, number] {
  const [a0, b0, c] = start;
  let a = a0 + dp;
  let b = b0 - dp;
  a = Math.max(MIN_PCT, Math.min(a, 100 - MIN_PCT - c));
  b = 100 - a - c;
  return [a, b, c];
}

/** Arrastra entre centro y derecha; a fijo */
function applyDragMidRight(start: [number, number, number], dp: number): [number, number, number] {
  const [a, b0, c0] = start;
  let b = b0 + dp;
  let c = c0 - dp;
  c = Math.max(MIN_PCT, Math.min(c, 100 - MIN_PCT - a));
  b = 100 - a - c;
  return [a, b, c];
}

const WIDE_QUERY = "(min-width: 1101px)";

export function useWorkspaceColumnWidths() {
  const gridRef = useRef<HTMLDivElement>(null);
  const [cols, setCols] = useState<[number, number, number]>(loadInitial);
  const latestRef = useRef<[number, number, number]>(cols);
  latestRef.current = cols;

  const [wide, setWide] = useState(
    () => typeof window !== "undefined" && window.matchMedia(WIDE_QUERY).matches,
  );

  useEffect(() => {
    const mq = window.matchMedia(WIDE_QUERY);
    const onChange = () => setWide(mq.matches);
    mq.addEventListener("change", onChange);
    return () => mq.removeEventListener("change", onChange);
  }, []);

  const persist = useCallback((next: [number, number, number]) => {
    try {
      localStorage.setItem(
        STORAGE_KEY,
        JSON.stringify(next.map((x) => Math.round(x * 100) / 100)),
      );
    } catch {
      /* ignore */
    }
  }, []);

  const reset = useCallback(() => {
    const d = [...DEFAULT_PCTS] as [number, number, number];
    latestRef.current = d;
    setCols(d);
    persist(d);
  }, [persist]);

  const dragRef = useRef<{
    which: 0 | 1;
    startX: number;
    startCols: [number, number, number];
  } | null>(null);

  const onMove = useCallback((e: MouseEvent) => {
    const d = dragRef.current;
    const el = gridRef.current;
    if (!d || !el) return;
    const w = el.offsetWidth;
    if (w <= 0) return;
    const inner = Math.max(1, w - 2 * WORKSPACE_RESIZE_HANDLE_PX);
    const dp = ((e.clientX - d.startX) / inner) * 100;
    const next =
      d.which === 0
        ? applyDragLeftRight(d.startCols, dp)
        : applyDragMidRight(d.startCols, dp);
    latestRef.current = next;
    setCols(next);
  }, []);

  const onUp = useCallback(() => {
    dragRef.current = null;
    document.body.style.removeProperty("cursor");
    document.body.style.removeProperty("user-select");
    document.removeEventListener("mousemove", onMove);
    document.removeEventListener("mouseup", onUp);
    persist(latestRef.current);
  }, [onMove, persist]);

  const onMouseDown = useCallback(
    (which: 0 | 1) => (e: ReactMouseEvent) => {
      if (e.button !== 0) return;
      e.preventDefault();
      dragRef.current = {
        which,
        startX: e.clientX,
        startCols: [...latestRef.current],
      };
      document.body.style.cursor = "col-resize";
      document.body.style.userSelect = "none";
      document.addEventListener("mousemove", onMove);
      document.addEventListener("mouseup", onUp);
    },
    [onMove, onUp],
  );

  return {
    gridRef,
    cols,
    isResizable: wide,
    onMouseDownLeft: onMouseDown(0),
    onMouseDownRight: onMouseDown(1),
    resetWidths: reset,
  };
}
