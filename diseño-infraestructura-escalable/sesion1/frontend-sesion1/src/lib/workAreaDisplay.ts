/** Oculta el bloque ```json ... ``` en el hilo del chat (el historial ya se guarda sin él en el backend). */
export function stripDocvizWorkAreaJsonBlock(text: string): string {
  return text.replace(/```json\s*[\s\S]*?```/gi, "").trim();
}

/** Quita fences ```yaml completos (propuestas DocViz); el detalle de diff va al área de trabajo. */
export function stripYamlProposalsFence(text: string): string {
  return text.replace(/```yaml\s*[\s\S]*?```/gi, "").trim();
}

/**
 * Rutas de propuestas (`path:`) dentro de un bloque YAML o en texto suelto tipo proposals.
 */
export function extractProposalPaths(raw: string): string[] {
  const yamlFence = raw.match(/```yaml\s*([\s\S]*?)```/i);
  const block = yamlFence ? yamlFence[1] : raw;
  const paths: string[] = [];
  const lineList = /^\s*-\s*path:\s*(.+)$/gm;
  let m: RegExpExecArray | null;
  while ((m = lineList.exec(block)) !== null) {
    const p = m[1].trim();
    if (p) {
      paths.push(p);
    }
  }
  return [...new Set(paths)];
}

function tryParseDirectAnswerFromJsonFence(raw: string): string | null {
  const fence = raw.match(/```json\s*([\s\S]*?)```/i);
  if (!fence) {
    return null;
  }
  try {
    const j = JSON.parse(fence[1].trim()) as { kind?: string; answer?: unknown };
    if (j && j.kind === "direct" && typeof j.answer === "string") {
      const a = j.answer.trim();
      return a.length > 0 ? a : null;
    }
  } catch {
    return null;
  }
  return null;
}

/**
 * Texto mostrado en el hilo: prioriza el markdown del campo `answer` del JSON DocViz;
 * oculta fences técnicos; si hay `proposals` en YAML, añade solo la lista de rutas (los borradores siguen en el área de trabajo).
 */
export function formatChatAnswerForDisplay(raw: string): string {
  if (!raw?.trim()) {
    return "";
  }

  const paths = extractProposalPaths(raw);
  const fromJson = tryParseDirectAnswerFromJsonFence(raw);

  let body = fromJson ?? "";
  if (!body) {
    let t = stripDocvizWorkAreaJsonBlock(raw);
    t = stripYamlProposalsFence(t);
    body = t.trim();
  }

  if (paths.length > 0) {
    const list = paths.map((p) => `- \`${p}\``).join("\n");
    body = body
      ? `${body}\n\n**Archivos a ajustar**\n\n${list}`
      : `**Archivos a ajustar**\n\n${list}`;
  }

  if (!body.trim()) {
    if (/```json/i.test(raw)) {
      return (
        "*El asistente respondió con JSON pero no hay texto utilizable en `answer`, o el bloque está incompleto. Si pedías cambios en archivos, revisa el **área de trabajo**.*"
      );
    }
    return "";
  }
  return body;
}
