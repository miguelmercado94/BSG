/**
 * Debe coincidir con {@code DomainTaskService.RAG_CHAT_PROMPT_PREFIX} en el backend Java.
 * Si cambia el prefijo en el servidor, actualizar esta cadena para que el front pueda separar
 * el enunciado visible del bloque técnico enviado al modelo.
 */
export const RAG_CHAT_PROMPT_PREFIX = `Responde ÚNICAMENTE con un documento JSON válido (puedes envolverlo en \`\`\`json … \`\`\`). Sin texto antes del JSON ni después del JSON salvo el bloque YAML opcional descrito abajo.

Esquema obligatorio del JSON:
- Respuesta única: {"kind":"direct","answer":"markdown"}
- Plan por pasos: {"kind":"plan","steps":[{"order":1,"summary":"…","files":[{"path":"ruta/relativa.ext","change":"…"}]}]}
En \`files\` lista solo archivos a tocar en ese paso; si no hay, "files":[]. Enumera \`order\` 1,2,3,…

Casos:
1) Preguntas solo informativas (listar dependencias, explicar código, describir qué servicios o librerías usa el proyecto, resumir sin modificar archivos): usa {"kind":"direct","answer":"…"} con la respuesta completa en markdown dentro de "answer". NO añadas ningún bloque \`\`\`yaml después del JSON.

Las menciones @[repo:ruta] y @[soporte:clave] solo acotan contexto RAG; no son por sí solas una petición de edición. Si el usuario pregunta sobre un archivo citado (dependencias, qué hace, etc.), sigue siendo caso 1): responde en "answer" sin YAML.

No incluyas bloque \`\`\`yaml si no hay ediciones reales (blocks no vacíos). Nunca devuelvas proposals con blocks: [] solo para citar una ruta; el usuario ve la lista de archivos en la UI cuando sí hay cambios.

2) Solo cuando el enunciado pide explícitamente crear, editar, quitar o ajustar contenido en archivos del repositorio o de soporte (p. ej. «modifica docker-compose», «añade la dependencia en build.gradle»): después del JSON cierra con un único bloque \`\`\`yaml cuya raíz sea "proposals:" (path REPO/… o LOCAL/…, new, blocks con start/end/type/lines). No pongas "proposals" dentro del JSON. Si kind es "plan", puedes posponer el \`\`\`yaml al último paso que toque archivos.

Ejemplo solo informativo:
\`\`\`json
{"kind":"direct","answer":"En este repositorio las dependencias AWS aparecen en …"}
\`\`\`

Ejemplo con cambios de archivo (solo si el enunciado lo exige):
\`\`\`json
{"kind":"direct","answer":"Actualizo el compose para quitar redis."}
\`\`\`
\`\`\`yaml
proposals:
- path: REPO/findu/docker-compose.yml
  new: false
  blocks:
  - { start: 10, end: 12, type: REPLACE, lines: ["  x: y"] }
\`\`\`

Enunciado:


`;

export function splitRagChatQuestion(question: string): {
  entradaUsuario: string;
  promptFinal: string | null;
} {
  if (question.startsWith(RAG_CHAT_PROMPT_PREFIX)) {
    return {
      entradaUsuario: question.slice(RAG_CHAT_PROMPT_PREFIX.length).trim(),
      promptFinal: null,
    };
  }
  /** Si el prefijo del backend y esta cadena difieren (despliegues desalineados), igual separar por marcador común. */
  const legacy = question.match(/Enunciado:\s*\n\s*\n([\s\S]*)$/);
  if (legacy?.[1] != null && legacy[1].trim()) {
    return { entradaUsuario: legacy[1].trim(), promptFinal: null };
  }
  return { entradaUsuario: question, promptFinal: null };
}
