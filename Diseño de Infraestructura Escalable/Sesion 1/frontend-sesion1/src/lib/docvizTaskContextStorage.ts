const KEY = "docviz:workspaceTaskContext:v1";

export type StoredTaskContext = {
  taskId?: number;
  chatConversationId?: string | null;
  huCode: string;
  enunciado: string;
  cellLabel?: string;
  returnPath: string;
};

type StoredPayload = {
  userId: string;
  task: StoredTaskContext;
};

export function saveWorkspaceTaskContext(userId: string, task: StoredTaskContext): void {
  const uid = userId?.trim();
  if (!uid || !task.huCode?.trim()) return;
  try {
    const payload: StoredPayload = { userId: uid, task };
    sessionStorage.setItem(KEY, JSON.stringify(payload));
  } catch {
    /* private mode */
  }
}

export function loadWorkspaceTaskContext(userId: string): StoredTaskContext | null {
  const uid = userId?.trim();
  if (!uid) return null;
  try {
    const raw = sessionStorage.getItem(KEY);
    if (!raw) return null;
    const payload = JSON.parse(raw) as StoredPayload;
    if (!payload?.userId || payload.userId !== uid || !payload.task?.huCode?.trim()) {
      return null;
    }
    return payload.task;
  } catch {
    return null;
  }
}

export function clearWorkspaceTaskContext(): void {
  try {
    sessionStorage.removeItem(KEY);
  } catch {
    /* ignore */
  }
}
