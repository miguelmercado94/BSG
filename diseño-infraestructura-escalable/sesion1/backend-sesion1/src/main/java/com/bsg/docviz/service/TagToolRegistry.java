package com.bsg.docviz.service;

import com.bsg.docviz.dto.TagToolRefDto;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * Catálogo quemado: tags reconocidos y URLs de documentación / dependencias para inyectar en el prompt RAG
 * (equivalente práctico a “@tools” orientativos; el modelo no navega solo, pero puede citar estas fuentes).
 */
@Component
public class TagToolRegistry {

    private final LinkedHashMap<String, List<TagToolRefDto>> toolsByCanonicalTag = new LinkedHashMap<>();

    public TagToolRegistry() {
        put(
                "Java",
                List.of(
                        new TagToolRefDto(
                                "mvnrepo",
                                "Maven Repository",
                                "https://mvnrepository.com/",
                                "Buscar artefactos Maven y versiones publicadas."),
                        new TagToolRefDto(
                                "java-se-docs",
                                "Java SE — Oracle Docs",
                                "https://docs.oracle.com/en/java/",
                                "Documentación oficial del lenguaje y la API estándar.")));
        put(
                "Spring",
                List.of(
                        new TagToolRefDto(
                                "spring-boot-ref",
                                "Spring Boot reference",
                                "https://docs.spring.io/spring-boot/reference/",
                                "Configuración, starters y convenciones."),
                        new TagToolRefDto(
                                "spring-framework",
                                "Spring Framework",
                                "https://docs.spring.io/spring-framework/reference/",
                                "Core, Web, Data y contexto.")));
        put(
                "Python",
                List.of(
                        new TagToolRefDto(
                                "pypi",
                                "PyPI",
                                "https://pypi.org/",
                                "Paquetes publicados y versiones."),
                        new TagToolRefDto(
                                "python-docs",
                                "Python 3 documentation",
                                "https://docs.python.org/3/",
                                "Referencia del lenguaje y librería estándar.")));
        put(
                "Oracle",
                List.of(
                        new TagToolRefDto(
                                "oracle-db-doc",
                                "Oracle Database documentation",
                                "https://docs.oracle.com/en/database/",
                                "SQL, administración y características del motor."),
                        new TagToolRefDto(
                                "oracle-sql-ref",
                                "Oracle SQL Language Reference",
                                "https://docs.oracle.com/en/database/oracle/oracle-database/",
                                "Sintaxis SQL específica de Oracle.")));
        put(
                "SQL",
                List.of(
                        new TagToolRefDto(
                                "postgresql-docs",
                                "PostgreSQL documentation",
                                "https://www.postgresql.org/docs/",
                                "Este proyecto usa pgvector; conviene alinear con Postgres."),
                        new TagToolRefDto(
                                "sql-standard",
                                "PostgreSQL SQL commands",
                                "https://www.postgresql.org/docs/current/sql.html",
                                "Referencia de comandos SQL en Postgres.")));
        put(
                "Angular",
                List.of(
                        new TagToolRefDto(
                                "angular-dev",
                                "Angular (sitio actual)",
                                "https://angular.dev/",
                                "Guías, API y mejores prácticas."),
                        new TagToolRefDto(
                                "angular-cli",
                                "Angular CLI",
                                "https://angular.dev/tools/cli",
                                "Generación de proyectos y esquemas.")));
        put(
                "React",
                List.of(
                        new TagToolRefDto(
                                "react-dev",
                                "React",
                                "https://react.dev/",
                                "Documentación oficial (hooks, servidor, router según versión)."),
                        new TagToolRefDto(
                                "npm-js",
                                "npm",
                                "https://www.npmjs.com/",
                                "Paquetes JavaScript y versiones.")));
        put(
                "COBOL",
                List.of(
                        new TagToolRefDto(
                                "ibm-cobol",
                                "IBM Enterprise COBOL for z/OS",
                                "https://www.ibm.com/docs/en/cobol-zos",
                                "Manual de referencia típico en mainframe."),
                        new TagToolRefDto(
                                "gnu-cobol",
                                "GnuCOBOL",
                                "https://gnucobol.sourceforge.io/",
                                "Implementación open source y sintaxis.")));
    }

    private void put(String tag, List<TagToolRefDto> tools) {
        toolsByCanonicalTag.put(tag, List.copyOf(tools));
    }

    /** Nombres de tags en el orden del catálogo (para UI y GET /tags). */
    public List<String> allTagNames() {
        return new ArrayList<>(toolsByCanonicalTag.keySet());
    }

    /** Para el cliente: herramientas por cada tag canónico. */
    public Map<String, List<TagToolRefDto>> toolsByTagMap() {
        return Map.copyOf(toolsByCanonicalTag);
    }

    /**
     * Bloque de texto para el prompt RAG según {@code tags_csv} del repo (CSV case-insensitive respecto a los tags del catálogo).
     */
    public String buildPromptAugmentationForTagsCsv(String tagsCsv) {
        if (tagsCsv == null || tagsCsv.isBlank()) {
            return "";
        }
        List<String> tokens =
                Arrays.stream(tagsCsv.split(","))
                        .map(String::trim)
                        .filter(s -> !s.isEmpty())
                        .collect(Collectors.toList());
        if (tokens.isEmpty()) {
            return "";
        }
        Map<String, String> lowerToCanonical =
                toolsByCanonicalTag.keySet().stream()
                        .collect(Collectors.toMap(k -> k.toLowerCase(Locale.ROOT), k -> k, (a, b) -> a));
        Set<String> seenUrls = new LinkedHashSet<>();
        List<TagToolRefDto> merged = new ArrayList<>();
        List<String> matchedLabels = new ArrayList<>();
        for (String t : tokens) {
            String canon = lowerToCanonical.get(t.toLowerCase(Locale.ROOT));
            if (canon == null) {
                continue;
            }
            matchedLabels.add(canon);
            for (TagToolRefDto ref : toolsByCanonicalTag.getOrDefault(canon, List.of())) {
                String key = ref.url().trim().toLowerCase(Locale.ROOT);
                if (seenUrls.add(key)) {
                    merged.add(ref);
                }
            }
        }
        if (merged.isEmpty()) {
            return "";
        }
        String tagsLine = String.join(", ", matchedLabels);
        StringBuilder sb = new StringBuilder();
        sb.append("\n\n---\nReferencias web (@tools) sugeridas para los tags del repositorio (")
                .append(tagsLine)
                .append("):\n");
        for (TagToolRefDto r : merged) {
            sb.append("- ").append(r.title()).append(" → ").append(r.url());
            if (r.hint() != null && !r.hint().isBlank()) {
                sb.append(" — ").append(r.hint());
            }
            sb.append("\n");
        }
        sb.append(
                "Usa estas URLs solo como orientación o para citar fuentes externas; el código sigue siendo el del contexto [Fuente: …] anterior.\n");
        return sb.toString();
    }
}
