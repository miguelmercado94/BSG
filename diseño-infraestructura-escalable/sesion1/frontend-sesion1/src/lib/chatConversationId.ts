/**
 * Identificador de hilo en Firestore: `users/{uid}/conversations/{usuario_tarea_N}/messages`.
 * Coincide con la sanitización del backend (UserIdSanitizer).
 */
const STORAGE_PREFIX = "docviz:chatConversationId:";

/** Alineado con {@link com.bsg.docviz.security.UserIdSanitizer#forFilesystem}. */
function seg(s: string): string {
  const t = s.trim();
  if (t.length > 64) {
    return t.slice(0, 64).replace(/[^a-zA-Z0-9._-]/g, "_");
  }
  return t.replace(/[^a-zA-Z0-9._-]/g, "_");
}

/**
 * Con tarea: {@code usuario_hu_taskId_N} o con célula {@code usuario_celula_hu_taskId_N}.
 * Sin taskId: {@code usuario_hu_o_default_N} con un solo segmento numérico final (workspace genérico).
 */
export function buildChatConversationId(
  userId: string,
  opts?: {
    huCode?: string | null;
    threadIndex?: number;
    taskId?: number | null;
    cellName?: string | null;
  },
): string {
  const u = seg(userId);
  const t = opts?.huCode?.trim() ? seg(opts.huCode.trim()) : "default";
  const c = opts?.cellName?.trim() ? seg(opts.cellName.trim()) : null;
  if (opts?.taskId != null && Number.isFinite(opts.taskId)) {
    const tid = String(Math.trunc(opts.taskId));
    const n = String(opts?.threadIndex ?? 0);
    if (c) {
      return `${u}_${c}_${t}_${tid}_${n}`;
    }
    return `${u}_${t}_${tid}_${n}`;
  }
  const n = String(opts?.threadIndex ?? 0);
  return `${u}_${t}_${n}`;
}

/**
 * Prioridad: id persistido en BD (tarea) → mismo criterio con taskId/HU/célula → sessionStorage (F5) → default.
 */
export function resolveChatConversationId(
  userId: string | undefined,
  huCode: string | undefined | null,
  opts?: {
    /** Valor de {@code docviz_task.chat_conversation_id}; fuente de verdad. */
    persistedConversationId?: string | null;
    taskId?: number | null;
    cellName?: string | null;
  },
): string {
  if (!userId?.trim()) return "";
  const uid = userId.trim();
  const key = STORAGE_PREFIX + uid;
  const persisted = opts?.persistedConversationId?.trim();
  if (persisted) {
    try {
      sessionStorage.setItem(key, persisted);
    } catch {
      /* private mode */
    }
    return persisted;
  }
  if (huCode?.trim()) {
    const id = buildChatConversationId(uid, {
      huCode: huCode.trim(),
      taskId: opts?.taskId,
      threadIndex: 0,
      cellName: opts?.cellName,
    });
    try {
      sessionStorage.setItem(key, id);
    } catch {
      /* private mode */
    }
    return id;
  }
  try {
    const saved = sessionStorage.getItem(key);
    if (saved?.trim()) return saved.trim();
  } catch {
    /* ignore */
  }
  const id = buildChatConversationId(uid, { threadIndex: 0 });
  try {
    sessionStorage.setItem(key, id);
  } catch {
    /* ignore */
  }
  return id;
}
