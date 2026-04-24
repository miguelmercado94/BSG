import { useCallback, useEffect, useState } from "react";

import type { SupportDocument } from "../types";

const STORAGE_PREFIX = "docviz_support_";

function storageKey(userId: string): string {
  return `${STORAGE_PREFIX}${userId}`;
}

function loadFromStorage(userId: string): SupportDocument[] {
  if (!userId.trim()) return [];
  try {
    const raw = localStorage.getItem(storageKey(userId));
    if (!raw) return [];
    const parsed = JSON.parse(raw) as unknown;
    if (!Array.isArray(parsed)) return [];
    return parsed
      .filter(
        (x): x is SupportDocument =>
          x != null &&
          typeof x === "object" &&
          typeof (x as SupportDocument).id === "string" &&
          typeof (x as SupportDocument).name === "string" &&
          typeof (x as SupportDocument).content === "string",
      )
      .map((x) => ({
        ...x,
        updatedAt: typeof x.updatedAt === "number" ? x.updatedAt : Date.now(),
      }));
  } catch {
    return [];
  }
}

function saveToStorage(userId: string, docs: SupportDocument[]): void {
  if (!userId.trim()) return;
  try {
    localStorage.setItem(storageKey(userId), JSON.stringify(docs));
  } catch {
    /* quota / private mode */
  }
}

function newId(): string {
  if (typeof crypto !== "undefined" && typeof crypto.randomUUID === "function") {
    return crypto.randomUUID();
  }
  return `sup-${Date.now()}-${Math.random().toString(36).slice(2, 11)}`;
}

/** Normaliza nombre y fuerza extensión .md */
export function normalizeMdFilename(name: string): string {
  const trimmed = name.trim().replace(/[/\\]+/g, "_") || "soporte.md";
  return trimmed.toLowerCase().endsWith(".md") ? trimmed : `${trimmed}.md`;
}

function uniqueName(desired: string, existing: SupportDocument[]): string {
  const names = new Set(existing.map((d) => d.name));
  if (!names.has(desired)) return desired;
  const dot = desired.lastIndexOf(".");
  const base = dot > 0 ? desired.slice(0, dot) : desired;
  const ext = dot > 0 ? desired.slice(dot) : ".md";
  let n = 1;
  let candidate = `${base} (${n})${ext}`;
  while (names.has(candidate)) {
    n += 1;
    candidate = `${base} (${n})${ext}`;
  }
  return candidate;
}

export function useSupportDocuments(userId: string) {
  const [docs, setDocs] = useState<SupportDocument[]>(() => loadFromStorage(userId));

  useEffect(() => {
    setDocs(loadFromStorage(userId));
  }, [userId]);

  useEffect(() => {
    saveToStorage(userId, docs);
  }, [userId, docs]);

  const add = useCallback(
    (
      name: string,
      content: string,
      meta?: { objectKey?: string; storageFileName?: string },
    ): string => {
      const id = newId();
      setDocs((prev) => {
        const fileName = uniqueName(normalizeMdFilename(name), prev);
        const row: SupportDocument = { id, name: fileName, content, updatedAt: Date.now() };
        if (meta?.objectKey) row.objectKey = meta.objectKey;
        if (meta?.storageFileName) row.storageFileName = meta.storageFileName;
        return [...prev, row];
      });
      return id;
    },
    [],
  );

  const update = useCallback((id: string, content: string) => {
    setDocs((prev) =>
      prev.map((d) => (d.id === id ? { ...d, content, updatedAt: Date.now() } : d)),
    );
  }, []);

  const remove = useCallback((id: string) => {
    setDocs((prev) => prev.filter((d) => d.id !== id));
  }, []);

  return { docs, add, update, remove };
}
