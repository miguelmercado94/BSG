/** Oculta el bloque ```json ... ``` en el hilo del chat (el historial ya se guarda sin él en el backend). */
export function stripDocvizWorkAreaJsonBlock(text: string): string {
  return text.replace(/```json\s*[\s\S]*?```/gi, "").trim();
}

/**
 * Texto mostrado en el hilo: quita el JSON de propuestas.
 * Si el modelo solo devolvió un fence ```json (común en copias al área de trabajo), sin esto el mensaje queda en blanco
 * aunque el streaming se viera en el bloque de código.
 */
export function formatChatAnswerForDisplay(raw: string): string {
  const stripped = stripDocvizWorkAreaJsonBlock(raw);
  if (stripped.length > 0) {
    return stripped;
  }
  if (!raw.trim()) {
    return "";
  }
  if (/```json/i.test(raw)) {
    return (
      "*El modelo envió la propuesta solo como bloque JSON (oculto aquí). Revisa el **área de trabajo** abajo; si no hay tarjetas, el JSON no fue válido o no incluyó `proposals`.*"
    );
  }
  return raw.trim();
}
