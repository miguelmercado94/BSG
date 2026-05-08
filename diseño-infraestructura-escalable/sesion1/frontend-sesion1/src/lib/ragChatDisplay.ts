/**
 * Debe coincidir con {@code DomainTaskService.RAG_CHAT_PROMPT_PREFIX} en el backend Java.
 * Si cambia el prefijo en el servidor, actualizar esta cadena para que el front pueda separar
 * el enunciado visible del bloque técnico enviado al modelo.
 */
export const RAG_CHAT_PROMPT_PREFIX =
  "Responde ÚNICAMENTE con un documento JSON válido (puedes envolverlo en ```json … ```). Sin texto fuera del JSON.\n" +
  "Esquema obligatorio:\n" +
  '- Respuesta única: {"kind":"direct","answer":"markdown con la solución"}\n' +
  '- Plan por pasos: {"kind":"plan","steps":[{"order":1,"summary":"…",' +
  '"files":[{"path":"ruta/relativa.ext","change":"…"}]}]}\n' +
  'En `files` lista solo archivos a tocar en ese paso; si no hay, "files":[]. Enumera `order` 1,2,3,…\n' +
  "PROPUESTAS DE ARCHIVO (área de trabajo DocViz): si el enunciado pide crear, editar, quitar o ajustar " +
  "contenido en archivos del repositorio (p. ej. @[repo:…], docker-compose, YAML, código), después del JSON " +
  'añade un bloque ```yaml cuya raíz sea "proposals:" (path REPO/… o LOCAL/…, new, blocks con ' +
  "start/end/type/lines). No pongas \"proposals\" dentro del JSON. \"answer\" resume en markdown. " +
  "Si kind es \"plan\", puedes posponer el ```yaml al último paso que toque archivos.\n" +
  'Ejemplo mínimo (direct): ' +
  '{"kind":"direct","answer":"Quito redis del compose."}\n' +
  "```yaml\nproposals:\n- path: REPO/findu/docker-compose.yml\n  new: false\n  blocks:\n  " +
  '- { start: 10, end: 12, type: REPLACE, lines: ["  x: y"] }\n```\n' +
  "Enunciado:\n\n";

export function splitRagChatQuestion(question: string): {
  entradaUsuario: string;
  promptFinal: string | null;
} {
  if (question.startsWith(RAG_CHAT_PROMPT_PREFIX)) {
    return {
      entradaUsuario: question.slice(RAG_CHAT_PROMPT_PREFIX.length).trim(),
      promptFinal: question,
    };
  }
  return { entradaUsuario: question, promptFinal: null };
}
