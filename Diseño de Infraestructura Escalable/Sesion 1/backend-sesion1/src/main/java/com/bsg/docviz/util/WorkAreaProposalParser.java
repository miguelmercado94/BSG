package com.bsg.docviz.util;

import com.bsg.docviz.dto.WorkAreaChangeBlockDto;
import com.bsg.docviz.dto.WorkAreaDiffLineDto;
import com.bsg.docviz.dto.WorkAreaLineEditDto;
import com.bsg.docviz.dto.WorkAreaProposalItemDto;
import com.fasterxml.jackson.core.JsonParser;
import com.fasterxml.jackson.core.JsonToken;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Extrae el bloque JSON de propuestas de copia (área de trabajo) del texto del modelo y lo parsea.
 */
public final class WorkAreaProposalParser {

    private static final Logger log = LoggerFactory.getLogger(WorkAreaProposalParser.class);

    /** Misma idea que {@link RagChatPlanParser}: el modelo a menudo usa {@code ```} sin la palabra {@code json}. */
    private static final Pattern FENCED_JSON =
            Pattern.compile("```(?:json)?\\s*([\\s\\S]*?)```", Pattern.CASE_INSENSITIVE);

    private WorkAreaProposalParser() {}

    /** Quita los bloques {@code ```json ... ```} del texto (p. ej. para historial en Firestore). */
    public static String stripFencedJsonBlocks(String full) {
        if (full == null || full.isEmpty()) {
            return "";
        }
        String s = FENCED_JSON.matcher(full).replaceAll("");
        return s.trim();
    }

    public static List<WorkAreaProposalItemDto> parseProposals(String fullAnswer, ObjectMapper objectMapper) {
        if (fullAnswer == null || fullAnswer.isBlank()) {
            log.debug("WorkArea parse: respuesta vacía; no hay propuestas");
            return List.of();
        }
        List<WorkAreaProposalItemDto> fromYaml = WorkAreaProposalYamlParser.parseProposalsFromAnswer(fullAnswer);
        if (!fromYaml.isEmpty()) {
            return fromYaml;
        }
        List<WorkAreaProposalItemDto> fromLeading = tryParseProposalsFromLeadingJsonObject(fullAnswer, objectMapper);
        if (fromLeading != null) {
            return fromLeading;
        }

        String json = extractJsonPayload(fullAnswer);
        if (json == null || json.isBlank()) {
            boolean mentionsProposals = indexOfProposalsKey(fullAnswer.trim()) >= 0;
            log.warn(
                    "WorkArea parse: no se extrajo JSON (¿falta cercado ``` o objeto {{...}}?). "
                            + "mencionaClaveProposals={} charsRespuesta={}",
                    mentionsProposals,
                    fullAnswer.length());
            return List.of();
        }
        try {
            JsonNode root = objectMapper.readTree(json);
            JsonNode proposals = root.get("proposals");
            if (proposals == null || !proposals.isArray()) {
                String nodeDesc =
                        proposals == null ? "null" : ("no-array:" + proposals.getNodeType());
                log.warn(
                        "WorkArea parse: se esperaba proposals:[] en el JSON extraído; nodo={} — primeros 200 chars: {}",
                        nodeDesc,
                        json.length() > 200 ? json.substring(0, 200) + "…" : json);
                return List.of();
            }
            return parseProposalItems(proposals);
        } catch (Exception e) {
            log.warn("WorkArea parse: JSON de propuestas inválido — {}", e.toString(), e);
            return List.of();
        }
    }

    /**
     * Primera respuesta RAG suele ser un único objeto {@code { "kind":"direct", "proposals":[...] }} seguido a veces de más texto.
     * Jackson lee solo el primer valor JSON del buffer.
     *
     * @return lista si hubo array proposals; {@code null} si no aplica (se sigue con fences / heurística).
     */
    private static List<WorkAreaProposalItemDto> tryParseProposalsFromLeadingJsonObject(
            String fullAnswer, ObjectMapper objectMapper) {
        try (JsonParser p = objectMapper.getFactory().createParser(fullAnswer.trim())) {
            if (p.nextToken() != JsonToken.START_OBJECT) {
                return null;
            }
            JsonNode root = objectMapper.readTree(p);
            if (root == null || !root.has("proposals")) {
                return null;
            }
            JsonNode proposals = root.get("proposals");
            if (!proposals.isArray()) {
                return null;
            }
            if (proposals.isEmpty()) {
                return null;
            }
            log.debug("WorkArea parse: proposals tomadas del primer objeto JSON (p. ej. kind + proposals en la raíz)");
            return parseProposalItems(proposals);
        } catch (Exception e) {
            return null;
        }
    }

    private static List<WorkAreaProposalItemDto> parseProposalItems(JsonNode proposals) {
        int rawCount = proposals.size();
        List<WorkAreaProposalItemDto> out = new ArrayList<>();
        for (JsonNode p : proposals) {
            if (p == null || !p.isObject()) {
                continue;
            }
            WorkAreaProposalItemDto item = new WorkAreaProposalItemDto();
            item.setId(UUID.randomUUID().toString());
            String fn = text(p, "fileName");
            String ext = text(p, "extension");
            item.setExtension(ext != null ? ext.trim() : "");
            String content = text(p, "content");
            item.setContent(content != null ? content : "");
            String src = text(p, "sourcePath");
            item.setSourcePath(src != null && !src.isBlank() ? src.trim() : null);
            JsonNode ch = p.get("changeBlocks");
            if (ch != null && ch.isArray()) {
                List<WorkAreaChangeBlockDto> blocks = parseChangeBlocks(ch);
                if (!blocks.isEmpty()) {
                    item.setChangeBlocks(blocks);
                    if (item.getSourcePath() == null) {
                        for (WorkAreaChangeBlockDto b : blocks) {
                            if (b.getType() != null
                                    && "create_file".equalsIgnoreCase(b.getType().trim())
                                    && b.getPath() != null
                                    && !b.getPath().isBlank()) {
                                item.setSourcePath(b.getPath().trim());
                                break;
                            }
                        }
                    }
                }
            }
            if (fn == null || fn.isBlank()) {
                if (item.getSourcePath() != null && !item.getSourcePath().isBlank()) {
                    fn = baseName(item.getSourcePath());
                } else if (item.getChangeBlocks() != null) {
                    for (WorkAreaChangeBlockDto b : item.getChangeBlocks()) {
                        if (b.getPath() != null && !b.getPath().isBlank()) {
                            fn = baseName(b.getPath().trim());
                            break;
                        }
                    }
                }
            }
            if (fn == null || fn.isBlank()) {
                continue;
            }
            item.setFileName(fn.trim());
            JsonNode le = p.get("lineEdits");
            if (le != null && le.isArray()) {
                List<WorkAreaLineEditDto> lineEdits = new ArrayList<>();
                for (JsonNode edit : le) {
                    if (edit == null || !edit.isObject()) {
                        continue;
                    }
                    JsonNode s = edit.get("startLine");
                    JsonNode e = edit.get("endLine");
                    if (s == null || !s.isNumber() || e == null || !e.isNumber()) {
                        continue;
                    }
                    WorkAreaLineEditDto dto = new WorkAreaLineEditDto();
                    dto.setStartLine(s.asInt());
                    dto.setEndLine(e.asInt());
                    String rep = text(edit, "replacement");
                    dto.setReplacement(rep);
                    lineEdits.add(dto);
                }
                if (!lineEdits.isEmpty()) {
                    item.setLineEdits(lineEdits);
                }
            }
            JsonNode dl = p.get("diffLines");
            if (dl != null && dl.isArray()) {
                List<WorkAreaDiffLineDto> lines = new ArrayList<>();
                for (JsonNode line : dl) {
                    if (line == null || !line.isObject()) {
                        continue;
                    }
                    WorkAreaDiffLineDto d = new WorkAreaDiffLineDto();
                    String k = text(line, "kind");
                    d.setKind(k != null ? k.trim() : "context");
                    String t = text(line, "text");
                    d.setText(t != null ? t : "");
                    lines.add(d);
                }
                item.setDiffLines(lines);
            }
            out.add(item);
        }
        if (out.isEmpty() && rawCount > 0) {
            log.warn(
                    "WorkArea parse: \"proposals\" tenía {} elemento(s) pero ninguno válido "
                            + "(falta fileName/sourcePath/changeBlocks con path)",
                    rawCount);
        } else if (!out.isEmpty()) {
            log.info("WorkArea parse: {} propuesta(s) lista(s) para enriquecer", out.size());
        } else {
            log.info("WorkArea parse: array \"proposals\" vacío");
        }
        return out;
    }

    private static String extractJsonPayload(String full) {
        String last = null;
        Matcher m = FENCED_JSON.matcher(full);
        while (m.find()) {
            last = m.group(1).trim();
        }
        if (last != null && !last.isEmpty()) {
            return last;
        }
        return extractJsonObjectWithProposals(full);
    }

    /**
     * Algunos modelos envían {@code {"proposals":[...]}} sin fence {@code ```json}; intentamos aislar el objeto raíz.
     */
    private static String extractJsonObjectWithProposals(String full) {
        if (full == null || full.isBlank()) {
            return null;
        }
        String trimmed = full.trim();
        int keyIdx = indexOfProposalsKey(trimmed);
        if (keyIdx < 0) {
            return null;
        }
        int start = trimmed.lastIndexOf('{', keyIdx);
        if (start < 0) {
            return null;
        }
        int depth = 0;
        for (int i = start; i < trimmed.length(); i++) {
            char c = trimmed.charAt(i);
            if (c == '{') {
                depth++;
            } else if (c == '}') {
                depth--;
                if (depth == 0) {
                    return trimmed.substring(start, i + 1);
                }
            }
        }
        return null;
    }

    private static int indexOfProposalsKey(String s) {
        int a = s.indexOf("\"proposals\"");
        if (a >= 0) {
            return a;
        }
        return s.indexOf("'proposals'");
    }

    private static String text(JsonNode n, String field) {
        JsonNode v = n.get(field);
        if (v == null || v.isNull()) {
            return null;
        }
        if (v.isTextual()) {
            return v.asText();
        }
        return v.toString();
    }

    private static String baseName(String path) {
        if (path == null || path.isEmpty()) {
            return "";
        }
        int a = path.lastIndexOf('/');
        int b = path.lastIndexOf('\\');
        int i = Math.max(a, b);
        return i >= 0 ? path.substring(i + 1) : path;
    }

    private static List<WorkAreaChangeBlockDto> parseChangeBlocks(JsonNode array) {
        List<WorkAreaChangeBlockDto> out = new ArrayList<>();
        for (JsonNode n : array) {
            if (n == null || !n.isObject()) {
                continue;
            }
            WorkAreaChangeBlockDto b = new WorkAreaChangeBlockDto();
            b.setId(text(n, "id"));
            b.setType(text(n, "type"));
            b.setContextBefore(stringArrayLineList(n, "context_before"));
            b.setOriginal(stringArrayLineList(n, "original"));
            b.setReplacement(stringArrayLineList(n, "replacement"));
            b.setContextAfter(stringArrayLineList(n, "context_after"));
            b.setPath(text(n, "path"));
            b.setContent(stringArrayLineList(n, "content"));
            out.add(b);
        }
        return out;
    }

    private static List<String> stringArrayLineList(JsonNode n, String field) {
        JsonNode a = n.get(field);
        if (a == null || !a.isArray()) {
            return List.of();
        }
        List<String> list = new ArrayList<>();
        for (JsonNode x : a) {
            if (x == null || x.isNull()) {
                list.add("");
            } else if (x.isTextual()) {
                list.add(x.asText());
            } else {
                list.add(x.toString());
            }
        }
        return list;
    }
}
