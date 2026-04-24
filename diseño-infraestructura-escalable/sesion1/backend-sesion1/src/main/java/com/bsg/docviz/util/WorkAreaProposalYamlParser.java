package com.bsg.docviz.util;

import com.bsg.docviz.dto.WorkAreaProposalItemDto;
import com.bsg.docviz.dto.WorkAreaYamlProposalBlockDto;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.yaml.snakeyaml.LoaderOptions;
import org.yaml.snakeyaml.Yaml;
import org.yaml.snakeyaml.constructor.SafeConstructor;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Extrae y parsea el YAML de propuestas del modelo ({@code proposals:} con {@code path}, {@code new}, {@code blocks}).
 */
public final class WorkAreaProposalYamlParser {

    private static final Logger log = LoggerFactory.getLogger(WorkAreaProposalYamlParser.class);

    private static final Pattern FENCED_YAML =
            Pattern.compile("```(?:yaml|yml)?\\s*([\\s\\S]*?)```", Pattern.CASE_INSENSITIVE);

    private WorkAreaProposalYamlParser() {}

    /** Quita bloques {@code ```yaml … ```} del texto (p. ej. historial Firestore). */
    public static String stripFencedYamlBlocks(String full) {
        if (full == null || full.isEmpty()) {
            return "";
        }
        return FENCED_YAML.matcher(full).replaceAll("").trim();
    }

    public static List<WorkAreaProposalItemDto> parseProposalsFromAnswer(String fullAnswer) {
        if (fullAnswer == null || fullAnswer.isBlank()) {
            return List.of();
        }
        String yaml = extractYamlPayload(fullAnswer);
        if (yaml == null || yaml.isBlank()) {
            return List.of();
        }
        try {
            LoaderOptions opts = new LoaderOptions();
            opts.setMaxAliasesForCollections(50);
            Yaml snake = new Yaml(new SafeConstructor(opts));
            Object loaded = snake.load(yaml);
            if (!(loaded instanceof Map<?, ?> root)) {
                log.warn("WorkArea YAML: raíz no es mapa");
                return List.of();
            }
            Object proposalsNode = root.get("proposals");
            if (!(proposalsNode instanceof List<?> proposalList)) {
                log.warn("WorkArea YAML: falta proposals: como lista");
                return List.of();
            }
            List<WorkAreaProposalItemDto> out = new ArrayList<>();
            for (Object rawItem : proposalList) {
                if (!(rawItem instanceof Map<?, ?> m)) {
                    continue;
                }
                WorkAreaProposalItemDto item = mapOneProposal(m);
                if (item != null) {
                    out.add(item);
                }
            }
            if (!out.isEmpty()) {
                log.info("WorkArea YAML: {} propuesta(s) parseada(s)", out.size());
            }
            return out;
        } catch (RuntimeException e) {
            log.warn("WorkArea YAML: parse inválido — {}", e.toString());
            return List.of();
        }
    }

    private static WorkAreaProposalItemDto mapOneProposal(Map<?, ?> m) {
        String path = stringVal(m.get("path"));
        if (path == null || path.isBlank()) {
            return null;
        }
        WorkAreaProposalPathCodec.Parsed parsed;
        try {
            parsed = WorkAreaProposalPathCodec.parse(path);
        } catch (IllegalArgumentException ex) {
            log.warn("WorkArea YAML: path inválido — {}", ex.getMessage());
            return null;
        }
        Object blocksObj = m.get("blocks");
        if (!(blocksObj instanceof List<?> blockList) || blockList.isEmpty()) {
            log.warn("WorkArea YAML: sin blocks para path={}", path);
            return null;
        }
        List<WorkAreaYamlProposalBlockDto> blocks = new ArrayList<>();
        for (Object b : blockList) {
            if (!(b instanceof Map<?, ?> bm)) {
                continue;
            }
            WorkAreaYamlProposalBlockDto dto = mapBlock(bm);
            if (dto != null) {
                blocks.add(dto);
            }
        }
        if (blocks.isEmpty()) {
            return null;
        }
        WorkAreaProposalItemDto item = new WorkAreaProposalItemDto();
        item.setId(UUID.randomUUID().toString());
        item.setYamlBlocks(blocks);
        item.setProposalOriginKind(parsed.kind().name());
        if (parsed.kind() == WorkAreaProposalPathCodec.Kind.REPO) {
            item.setSourcePath(parsed.repoRelativePath());
        } else {
            item.setSourcePath(WorkAreaProposalPathCodec.syntheticRepoRelativePath(parsed));
            item.setLocalS3Bucket(parsed.s3Bucket());
            item.setLocalS3ObjectKey(parsed.s3Key());
        }
        String base = baseName(
                parsed.kind() == WorkAreaProposalPathCodec.Kind.REPO
                        ? parsed.repoRelativePath()
                        : parsed.s3Key());
        item.setFileName(base);
        int dot = base.lastIndexOf('.');
        item.setExtension(dot > 0 ? base.substring(dot + 1) : "");
        item.setContent("");
        Boolean yn = boolVal(m.get("new"));
        if (Boolean.TRUE.equals(yn)) {
            item.setYamlNewFile(true);
        }
        return item;
    }

    private static WorkAreaYamlProposalBlockDto mapBlock(Map<?, ?> bm) {
        Integer start = intVal(bm.get("start"));
        Integer end = intVal(bm.get("end"));
        String type = stringVal(bm.get("type"));
        if (start == null || end == null || type == null || type.isBlank()) {
            return null;
        }
        WorkAreaYamlProposalBlockDto dto = new WorkAreaYamlProposalBlockDto();
        dto.setStart(start);
        dto.setEnd(end);
        dto.setType(type.trim());
        Object linesNode = bm.get("lines");
        if (linesNode instanceof List<?> lineList) {
            List<String> lines = new ArrayList<>();
            for (Object line : lineList) {
                if (line == null) {
                    lines.add("");
                } else {
                    lines.add(String.valueOf(line));
                }
            }
            dto.setLines(lines);
        } else {
            dto.setLines(new ArrayList<>());
        }
        return dto;
    }

    private static String extractYamlPayload(String full) {
        String last = null;
        Matcher mat = FENCED_YAML.matcher(full);
        while (mat.find()) {
            String inner = mat.group(1).trim();
            if (inner.startsWith("proposals:")) {
                last = inner;
            }
        }
        if (last != null) {
            return last;
        }
        String t = full.trim();
        if (t.startsWith("proposals:")) {
            return t;
        }
        return null;
    }

    private static String stringVal(Object o) {
        if (o == null) {
            return null;
        }
        String s = String.valueOf(o).trim();
        return s.isEmpty() ? null : s;
    }

    private static Boolean boolVal(Object o) {
        if (o instanceof Boolean b) {
            return b;
        }
        if (o instanceof String s) {
            if ("true".equalsIgnoreCase(s.trim())) {
                return true;
            }
            if ("false".equalsIgnoreCase(s.trim())) {
                return false;
            }
        }
        return null;
    }

    private static Integer intVal(Object o) {
        if (o instanceof Number n) {
            return n.intValue();
        }
        if (o instanceof String s) {
            try {
                return Integer.parseInt(s.trim());
            } catch (NumberFormatException ignored) {
                return null;
            }
        }
        return null;
    }

    private static String baseName(String path) {
        if (path == null || path.isEmpty()) {
            return "file";
        }
        int a = path.lastIndexOf('/');
        return a >= 0 ? path.substring(a + 1) : path;
    }
}
