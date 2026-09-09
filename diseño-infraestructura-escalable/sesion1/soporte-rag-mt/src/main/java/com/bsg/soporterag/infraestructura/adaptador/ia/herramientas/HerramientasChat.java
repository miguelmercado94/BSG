package com.bsg.soporterag.infraestructura.adaptador.ia.herramientas;

import com.bsg.soporterag.aplicacion.dto.response.MensajeChatDto;
import com.bsg.soporterag.aplicacion.mapperdto.TareaDtoMapper;
import com.bsg.soporterag.aplicacion.servicio.ServicioBucketS3;
import com.bsg.soporterag.aplicacion.servicio.ServicioDeParches;
import com.bsg.soporterag.aplicacion.servicio.ServicioJGit;
import com.bsg.soporterag.aplicacion.servicio.TareaServicio;
import com.bsg.soporterag.dominio.modelo.RolBucketS3;
import com.bsg.soporterag.infraestructura.adaptador.ia.model.*;
import org.jsoup.Jsoup;
import org.springframework.ai.tool.annotation.Tool;
import org.springframework.ai.tool.annotation.ToolParam;
import org.springframework.context.annotation.Description;
import org.springframework.stereotype.Component;
import org.springframework.util.CollectionUtils;
import org.springframework.util.StringUtils;
import reactor.core.publisher.Mono;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.stream.Collectors;

@Component
@Description("Herramientas para consultar información y proponer cambios en repositorios Git y contenido web")
public class HerramientasChat {

    private final ServicioJGit servicioJGit;
    private final ServicioDeParches servicioDeParches;
    private final ServicioBucketS3 servicioBucketS3;
    private final TareaServicio tareaServicio;
    private final TareaDtoMapper tareaDtoMapper;

    public HerramientasChat(
            ServicioJGit servicioJGit, 
            ServicioDeParches servicioDeParches, 
            ServicioBucketS3 servicioBucketS3, 
            TareaServicio tareaServicio, 
            TareaDtoMapper tareaDtoMapper) {
        this.servicioJGit = servicioJGit;
        this.servicioDeParches = servicioDeParches;
        this.servicioBucketS3 = servicioBucketS3;
        this.tareaServicio = tareaServicio;
        this.tareaDtoMapper = tareaDtoMapper;
    }

    @Tool(name = "obtenerHistorialChat", description = "Obtiene el historial completo de mensajes de una tarea específica.")
    public List<MensajeChatDto> obtenerHistorialChat(
            @ToolParam(description = "El código único de la tarea a consultar.") String codigoTarea
    ) {
        try {
            return tareaServicio.obtenerPorCodigo(codigoTarea)
                    .map(tarea -> tarea.getMsgChat().stream()
                            .map(tareaDtoMapper::aDto)
                            .collect(Collectors.toList()))
                    .blockOptional().orElse(Collections.emptyList());
        } catch (Exception e) {
            // En una herramienta, es mejor devolver una lista vacía o un mensaje de error simple
            // que dejar que la excepción se propague.
            return List.of(new MensajeChatDto()); // Devolver un objeto con error o vacío
        }
    }

    @Tool(name = "procesarPropuestaModificacion", description = "Procesa una propuesta de modificación de archivo, genera un parche .diff y lo guarda en el bucket de borradores de la tarea.")
    public String procesarPropuestaModificacion(
            @ToolParam(description = "El objeto JSON con la propuesta de modificación del archivo.") PropuestaModificacionArchivoDtoIa propuesta,
            @ToolParam(description = "El código de la tarea asociada a esta modificación.") String codigoTarea
    ) {
        try {
            // 1. Obtener contenido original
            Mono<byte[]> contenidoOriginalMono;
            if (StringUtils.hasText(propuesta.getCommit())) {
                contenidoOriginalMono = servicioJGit.extraerContenidoArchivoEnCommit(propuesta.getUrlRepo(), propuesta.getCommit(), propuesta.getFilePath());
            } else {
                contenidoOriginalMono = servicioJGit.extraerContenidoArchivo(propuesta.getUrlRepo(), propuesta.getRama(), propuesta.getFilePath());
            }
            String contenidoOriginal = new String(contenidoOriginalMono.block(), StandardCharsets.UTF_8);

            // 2. Generar el diff
            String diffContent = servicioDeParches.generarDiff(propuesta, contenidoOriginal).block();

            // 3. Determinar el nombre del archivo en S3
            String nombreBase = Paths.get(propuesta.getFilePath()).getFileName().toString();
            String prefijoBusqueda = codigoTarea + "/" + nombreBase + "_" + codigoTarea;
            
            long siguienteNumero = servicioBucketS3.listarArchivos(RolBucketS3.BORRADORES, prefijoBusqueda)
                    .count()
                    .block() + 1;

            String nombreArchivoDiff = String.format("%s_borrador_%d.diff", prefijoBusqueda, siguienteNumero);

            // 4. Guardar en S3
            servicioBucketS3.crearArchivo(RolBucketS3.BORRADORES, nombreArchivoDiff, diffContent.getBytes(StandardCharsets.UTF_8), "text/diff").block();

            // 5. Devolver la ruta S3 (presigned URL)
            return servicioBucketS3.generarUrlLectura(RolBucketS3.BORRADORES, nombreArchivoDiff).block();

        } catch (Exception e) {
            return "Error al procesar la propuesta de parche: " + e.getMessage();
        }
    }
    
    // ... resto de las herramientas ...
    @Tool(name = "consultarPaginaWeb", description = "Consulta en línea cualquier página web de documentación técnica, especificación oficial o API (Oracle PL/SQL, Microsoft Learn .NET, Python, Java, PostgreSQL, etc.) asociada a los tags del repositorio. Extrae contenido limpio, explicaciones de sintaxis, reglas y ejemplos de código. Opcionalmente recibe un tema o palabra clave para localizar o profundizar en una sección o sub-enlace relevante.")
    public String consultarPaginaWeb(
            @ToolParam(description = "La URL completa de la documentación o página web a consultar (ej: URLs configuradas en los tags del repositorio).") String url,
            @ToolParam(description = "Opcional. Palabra clave o concepto técnico a buscar dentro del contenido o sub-enlaces de la documentación (ej: 'cursores', 'LINQ', 'triggers', 'DbContext', 'exceptions', etc.).", required = false) String tema
    ) {
        if (!StringUtils.hasText(url)) {
            return "URL no válida";
        }
        String urlTrim = url.trim();

        // 1. Detección de ecosistemas de paquetes y dependencias
        if (urlTrim.contains("mvnrepository.com") || urlTrim.contains("search.maven.org") || urlTrim.contains("repo1.maven.org")) {
            return resolverConsultaMavenDesdeUrl(urlTrim, tema);
        }
        if (urlTrim.contains("nuget.org")) {
            return resolverConsultaNuget(urlTrim, tema);
        }
        if (urlTrim.contains("pypi.org")) {
            return resolverConsultaPypi(urlTrim, tema);
        }
        if (urlTrim.contains("npmjs.com")) {
            return resolverConsultaNpm(urlTrim, tema);
        }

        // 2. Extractor genérico de portales de documentación técnica (Oracle, Microsoft, etc.)
        return extraerDocumentacionGenerica(urlTrim, tema);
    }

    private String extraerDocumentacionGenerica(String url, String tema) {
        try {
            org.jsoup.nodes.Document doc = Jsoup.connect(url)
                    .userAgent("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36")
                    .header("Accept", "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8")
                    .header("Accept-Language", "es-ES,es;q=0.9,en;q=0.8")
                    .timeout(15000)
                    .followRedirects(true)
                    .get();

            // Si se especificó un tema, verificar si existe un sub-enlace directo en la página que apunte a ese tema
            if (StringUtils.hasText(tema)) {
                String subpaginaContenido = intentarNavegarSubenlace(doc, tema.trim());
                if (StringUtils.hasText(subpaginaContenido)) {
                    return subpaginaContenido;
                }
            }

            // Extraer y formatear contenido limpio de la página principal
            return formatearContenidoLimpio(doc, url, tema);

        } catch (org.jsoup.HttpStatusException e) {
            return "No se pudo acceder a la URL (" + url + ") debido a restricciones del servidor web (HTTP " + e.getStatusCode() + ").";
        } catch (IOException e) {
            return "Error al intentar acceder a la URL: " + e.getMessage();
        } catch (Exception e) {
            return "Ocurrió un error inesperado al procesar la página: " + e.getMessage();
        }
    }

    private String intentarNavegarSubenlace(org.jsoup.nodes.Document doc, String tema) {
        try {
            String[] palabras = tema.toLowerCase().split("\\s+");
            org.jsoup.select.Elements enlaces = doc.select("a[href]");

            org.jsoup.nodes.Element mejorEnlace = null;
            int maxCoincidencias = 0;

            for (org.jsoup.nodes.Element a : enlaces) {
                String href = a.attr("href");
                String texto = a.text().toLowerCase();
                String hrefLower = href.toLowerCase();

                if (href.startsWith("#") || href.startsWith("javascript:") || href.startsWith("mailto:")) {
                    continue;
                }

                int coincidencias = 0;
                for (String p : palabras) {
                    if (p.length() > 2 && (texto.contains(p) || hrefLower.contains(p))) {
                        coincidencias++;
                    }
                }

                if (coincidencias > maxCoincidencias) {
                    maxCoincidencias = coincidencias;
                    mejorEnlace = a;
                }
            }

            if (mejorEnlace != null && maxCoincidencias > 0) {
                String urlDestino = mejorEnlace.absUrl("href");
                if (StringUtils.hasText(urlDestino) && !urlDestino.equalsIgnoreCase(doc.baseUri())) {
                    org.jsoup.nodes.Document subDoc = Jsoup.connect(urlDestino)
                            .userAgent("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36")
                            .header("Accept", "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8")
                            .header("Accept-Language", "es-ES,es;q=0.9,en;q=0.8")
                            .timeout(15000)
                            .followRedirects(true)
                            .get();

                    String textoSub = formatearContenidoLimpio(subDoc, urlDestino, tema);
                    return "### Documentación encontrada para '" + tema + "' (" + mejorEnlace.text() + " - " + urlDestino + "):\n\n" + textoSub;
                }
            }
        } catch (Exception ignored) {
        }
        return null;
    }

    private String formatearContenidoLimpio(org.jsoup.nodes.Document doc, String url, String tema) {
        org.jsoup.nodes.Document cleanDoc = doc.clone();

        // 1. Eliminar elementos superfluos
        cleanDoc.select("script, style, nav, header, footer, aside, noscript, iframe, .sidebar, .navbar, .menu, .cookie-consent, #cookie-banner, [role='navigation'], [role='banner']").remove();

        // 2. Extraer contenedor principal
        org.jsoup.nodes.Element contentElem = cleanDoc.selectFirst("main, article, [role='main'], #content, .content, .documentation, #main-column, body");
        if (contentElem == null) {
            contentElem = cleanDoc.body();
        }

        // 3. Formatear bloques de código
        for (org.jsoup.nodes.Element pre : contentElem.select("pre")) {
            String codeText = pre.text();
            pre.text("\n```\n" + codeText + "\n```\n");
        }

        // 4. Formatear encabezados
        for (int h = 1; h <= 4; h++) {
            String prefix = "#".repeat(h) + " ";
            for (org.jsoup.nodes.Element elem : contentElem.select("h" + h)) {
                elem.text("\n" + prefix + elem.text() + "\n");
            }
        }

        // 5. Formatear listas
        for (org.jsoup.nodes.Element li : contentElem.select("li")) {
            li.text("\n- " + li.text());
        }

        String titulo = StringUtils.hasText(cleanDoc.title()) ? cleanDoc.title() : url;
        String texto = contentElem.text();

        // Limpiar espacios en blanco excesivos
        texto = texto.replaceAll("[ \t]+", " ").replaceAll("\n\\s*\n", "\n\n").trim();

        // 6. Recolectar secciones o enlaces de interés si no son excesivos
        StringBuilder sb = new StringBuilder();
        sb.append("## ").append(titulo).append("\n");
        sb.append("**Fuente:** ").append(url).append("\n\n");

        if (texto.length() > 8500) {
            sb.append(texto, 0, 8500).append("\n\n... [contenido truncado para contexto]");
        } else {
            sb.append(texto);
        }

        // Si es una página corta o de índice, agregar lista de enlaces de secciones
        org.jsoup.select.Elements enlaces = contentElem.select("a[href]");
        List<String> secciones = new ArrayList<>();
        for (org.jsoup.nodes.Element a : enlaces) {
            String t = a.text().trim();
            String href = a.absUrl("href");
            if (t.length() > 3 && StringUtils.hasText(href) && !href.startsWith("#") && !secciones.contains(t) && secciones.size() < 8) {
                secciones.add("- [" + t + "](" + href + ")");
            }
        }

        if (!secciones.isEmpty() && texto.length() < 4000) {
            sb.append("\n\n### Secciones y capítulos disponibles en este recurso:\n");
            sb.append(String.join("\n", secciones));
        }

        return sb.toString();
    }

    private String resolverConsultaNuget(String url, String tema) {
        try {
            String query = null;
            if (url.contains("/packages/")) {
                String sub = url.substring(url.indexOf("/packages/") + "/packages/".length());
                query = sub.split("/")[0];
            } else if (StringUtils.hasText(tema)) {
                query = tema.trim();
            }

            if (!StringUtils.hasText(query)) {
                return "Repositorio NuGet (.NET) disponible. Especifica el nombre del paquete para consultar sus versiones más recientes.";
            }

            String apiUrl = "https://api-v2v3search-0.nuget.org/query?q=" + java.net.URLEncoder.encode(query, StandardCharsets.UTF_8) + "&take=3";
            String json = Jsoup.connect(apiUrl)
                    .userAgent("Mozilla/5.0")
                    .ignoreContentType(true)
                    .timeout(6000)
                    .execute()
                    .body();

            com.fasterxml.jackson.databind.JsonNode root = new com.fasterxml.jackson.databind.ObjectMapper().readTree(json);
            com.fasterxml.jackson.databind.JsonNode data = root.path("data");
            if (!data.isArray() || data.isEmpty()) {
                return "No se encontraron paquetes en NuGet para '" + query + "'.";
            }

            StringBuilder sb = new StringBuilder("### Paquetes NuGet (.NET) encontrados para '").append(query).append("':\n\n");
            for (com.fasterxml.jackson.databind.JsonNode pkg : data) {
                String id = pkg.path("id").asText();
                String ver = pkg.path("version").asText();
                String desc = pkg.path("description").asText("");
                String projectUrl = pkg.path("projectUrl").asText("");
                sb.append("- **`").append(id).append("`**: versión **").append(ver).append("**\n");
                if (StringUtils.hasText(desc)) {
                    sb.append("  ").append(desc.length() > 150 ? desc.substring(0, 150) + "..." : desc).append("\n");
                }
                if (StringUtils.hasText(projectUrl)) {
                    sb.append("  [Sitio del proyecto](").append(projectUrl).append(")\n");
                }
            }
            return sb.toString();

        } catch (Exception e) {
            return "Error al consultar NuGet para '" + url + "': " + e.getMessage();
        }
    }

    private String resolverConsultaPypi(String url, String tema) {
        try {
            String pkg = null;
            if (url.contains("/project/")) {
                String sub = url.substring(url.indexOf("/project/") + "/project/".length());
                pkg = sub.split("/")[0];
            } else if (StringUtils.hasText(tema)) {
                pkg = tema.trim();
            }

            if (!StringUtils.hasText(pkg)) {
                return "Repositorio PyPI (Python) disponible. Especifica el paquete para consultar su versión más reciente.";
            }

            String apiUrl = "https://pypi.org/pypi/" + java.net.URLEncoder.encode(pkg, StandardCharsets.UTF_8) + "/json";
            String json = Jsoup.connect(apiUrl)
                    .userAgent("Mozilla/5.0")
                    .ignoreContentType(true)
                    .timeout(6000)
                    .execute()
                    .body();

            com.fasterxml.jackson.databind.JsonNode root = new com.fasterxml.jackson.databind.ObjectMapper().readTree(json);
            com.fasterxml.jackson.databind.JsonNode info = root.path("info");
            String name = info.path("name").asText();
            String ver = info.path("version").asText();
            String summary = info.path("summary").asText("");
            String homePage = info.path("home_page").asText("");

            return String.format(
                    """
                    ### Paquete PyPI (Python): %s
                    - Última versión: **%s**
                    - Descripción: %s
                    - Documentación/Home: %s
                    """,
                    name, ver, summary, homePage
            );

        } catch (org.jsoup.HttpStatusException e) {
            if (e.getStatusCode() == 404) {
                return "El paquete Python no fue encontrado en PyPI (HTTP 404).";
            }
            return "Error al consultar PyPI: HTTP " + e.getStatusCode();
        } catch (Exception e) {
            return "Error al consultar PyPI: " + e.getMessage();
        }
    }

    private String resolverConsultaNpm(String url, String tema) {
        try {
            String pkg = null;
            if (url.contains("/package/")) {
                String sub = url.substring(url.indexOf("/package/") + "/package/".length());
                pkg = sub.split("/")[0];
            } else if (StringUtils.hasText(tema)) {
                pkg = tema.trim();
            }

            if (!StringUtils.hasText(pkg)) {
                return "Registro npm (JavaScript/TypeScript) disponible. Especifica el paquete a consultar.";
            }

            String apiUrl = "https://registry.npmjs.org/" + java.net.URLEncoder.encode(pkg, StandardCharsets.UTF_8) + "/latest";
            String json = Jsoup.connect(apiUrl)
                    .userAgent("Mozilla/5.0")
                    .ignoreContentType(true)
                    .timeout(6000)
                    .execute()
                    .body();

            com.fasterxml.jackson.databind.JsonNode root = new com.fasterxml.jackson.databind.ObjectMapper().readTree(json);
            String name = root.path("name").asText();
            String ver = root.path("version").asText();
            String desc = root.path("description").asText("");

            return String.format(
                    """
                    ### Paquete npm (JavaScript/TypeScript): %s
                    - Última versión: **%s**
                    - Descripción: %s
                    """,
                    name, ver, desc
            );

        } catch (org.jsoup.HttpStatusException e) {
            if (e.getStatusCode() == 404) {
                return "El paquete no fue encontrado en el registro npm (HTTP 404).";
            }
            return "Error al consultar npm: HTTP " + e.getStatusCode();
        } catch (Exception e) {
            return "Error al consultar npm: " + e.getMessage();
        }
    }

    private String resolverConsultaMavenDesdeUrl(String url, String tema) {
        if (StringUtils.hasText(tema)) {
            return resolverYConsultarMaven(tema.trim());
        }
        if (url.contains("/artifact/")) {
            try {
                String sub = url.substring(url.indexOf("/artifact/") + "/artifact/".length());
                String[] parts = sub.split("/");
                if (parts.length >= 2) {
                    return resolverYConsultarMaven(parts[0] + ":" + parts[1]);
                }
            } catch (Exception ignored) {
            }
        }
        return """
               Repositorio Maven Central disponible en línea.
               Para consultar versiones exactas y actualizadas de cualquier dependencia, utiliza la herramienta 'consultarDependenciasMaven' indicando las coordenadas (por ejemplo: 'software.amazon.awssdk:dynamodb', 'com.amazonaws:aws-java-sdk-sqs', 'software.amazon.awssdk:bom') o especifica el nombre en el parámetro 'tema'.
               """;
    }

    private String resolverYConsultarMaven(String query) {
        try {
            String g = null;
            String a = null;

            if (query.contains(":")) {
                String[] parts = query.split(":", 2);
                g = parts[0].trim();
                a = parts[1].trim();
            } else if (query.startsWith("aws-java-sdk-")) {
                g = "com.amazonaws";
                a = query;
            } else if (List.of("dynamodb", "s3", "sqs", "sns", "kms", "secretsmanager", "bom", "apache-client", "netty-nio-client", "cognitoidentityprovider", "s3control").contains(query.toLowerCase())) {
                g = "software.amazon.awssdk";
                a = query.toLowerCase();
            } else if (query.startsWith("spring-boot-starter") || query.startsWith("spring-boot")) {
                g = "org.springframework.boot";
                a = query;
            } else {
                // Consultar buscador público de Sonatype Central Solr
                try {
                    String solrUrl = "https://central.sonatype.com/solrsearch/select?q=" + java.net.URLEncoder.encode(query, StandardCharsets.UTF_8) + "&rows=3&wt=json";
                    String json = Jsoup.connect(solrUrl)
                            .userAgent("Mozilla/5.0 (Windows NT 10.0; Win64; x64)")
                            .ignoreContentType(true)
                            .timeout(5000)
                            .execute()
                            .body();
                    com.fasterxml.jackson.databind.JsonNode root = new com.fasterxml.jackson.databind.ObjectMapper().readTree(json);
                    com.fasterxml.jackson.databind.JsonNode docs = root.path("response").path("docs");
                    if (docs.isArray() && !docs.isEmpty()) {
                        g = docs.get(0).path("g").asText(null);
                        a = docs.get(0).path("a").asText(null);
                    }
                } catch (Exception ignored) {
                }
            }

            if (!StringUtils.hasText(g) || !StringUtils.hasText(a)) {
                return "No se pudieron determinar las coordenadas Maven para '" + query + "'. Por favor especifica el formato 'groupId:artifactId' (por ejemplo, 'software.amazon.awssdk:dynamodb').";
            }

            String path = g.replace('.', '/') + "/" + a;
            String metadataUrl = "https://repo1.maven.org/maven2/" + path + "/maven-metadata.xml";

            org.jsoup.nodes.Document doc = Jsoup.connect(metadataUrl)
                    .userAgent("Mozilla/5.0 (Windows NT 10.0; Win64; x64)")
                    .parser(org.jsoup.parser.Parser.xmlParser())
                    .timeout(6000)
                    .get();

            String latest = doc.selectFirst("latest") != null ? doc.selectFirst("latest").text() : null;
            String release = doc.selectFirst("release") != null ? doc.selectFirst("release").text() : latest;
            String updated = doc.selectFirst("lastUpdated") != null ? doc.selectFirst("lastUpdated").text() : "N/A";

            List<String> versionesRecientes = doc.select("version").stream()
                    .map(org.jsoup.nodes.Element::text)
                    .toList();

            List<String> ultimasCinco = versionesRecientes.subList(Math.max(0, versionesRecientes.size() - 5), versionesRecientes.size());

            return String.format(
                    """
                    Coordenadas Maven Central: %s:%s
                    - Última versión (latest): %s
                    - Última versión estable (release): %s
                    - Última actualización: %s
                    - Versiones recientes publicadas: %s
                    - Repositorio oficial: %s
                    """,
                    g, a,
                    release != null ? release : "No especificada",
                    release != null ? release : "No especificada",
                    updated,
                    String.join(", ", ultimasCinco),
                    "https://repo1.maven.org/maven2/" + path + "/"
            );

        } catch (org.jsoup.HttpStatusException e) {
            if (e.getStatusCode() == 404) {
                return "El artefacto '" + query + "' no fue encontrado en Maven Central (HTTP 404).";
            }
            return "Error al consultar Maven Central: HTTP " + e.getStatusCode();
        } catch (Exception e) {
            return "Error al consultar dependencias en Maven Central: " + e.getMessage();
        }
    }

    @Tool(name = "consultarRamasRepositorio", description = "Consulta las ramas de un repositorio. Opcionalmente, puede verificar la existencia y último commit de archivos específicos en cada rama.")
    public ConsultaRamasResponseDtoIa consultarRamas(
            @ToolParam(description = "La URL completa del repositorio Git a consultar.") String urlRepo,
            @ToolParam(description = "Lista opcional de rutas de archivos para verificar en cada rama.", required = false) List<String> filePaths
    ) {
        if (CollectionUtils.isEmpty(filePaths)) {
            List<RamaDtoIa> ramas = servicioJGit.extraerRamas(urlRepo)
                    .map(ramaGit -> new RamaDtoIa(
                            ramaGit.nombre(),
                            new CommitDtoIa(
                                    ramaGit.ultimoCommit().hash(),
                                    ramaGit.ultimoCommit().mensaje(),
                                    ramaGit.ultimoCommit().autor()
                            ),
                            null
                    ))
                    .collectList()
                    .block();
            return new ConsultaRamasResponseDtoIa(ramas);
        } else {
            var resultadoMapa = servicioJGit.consultarRamasYArchivos(urlRepo, filePaths).block();
            if (resultadoMapa == null) {
                return new ConsultaRamasResponseDtoIa(new ArrayList<>());
            }

            List<RamaDtoIa> ramas = resultadoMapa.entrySet().stream()
                    .map(entry -> {
                        var ramaGit = entry.getKey();
                        var archivosGit = entry.getValue();

                        var archivosDto = archivosGit.stream()
                                .map(info -> new ArchivoRamaDtoIa(
                                        info.ruta(),
                                        info.existe(),
                                        info.existe() ? new CommitDtoIa(
                                                info.ultimoCommit().hash(),
                                                info.ultimoCommit().mensaje(),
                                                info.ultimoCommit().autor()
                                        ) : null
                                ))
                                .collect(Collectors.toList());

                        return new RamaDtoIa(
                                ramaGit.nombre(),
                                new CommitDtoIa(
                                        ramaGit.ultimoCommit().hash(),
                                        ramaGit.ultimoCommit().mensaje(),
                                        ramaGit.ultimoCommit().autor()
                                ),
                                archivosDto
                        );
                    })
                    .collect(Collectors.toList());
            
            return new ConsultaRamasResponseDtoIa(ramas);
        }
    }

    @Tool(name = "obtenerContenidoArchivo", description = "Obtiene el contenido de un archivo en una rama y/o commit específico de un repositorio.")
    public String obtenerContenidoArchivo(
            @ToolParam(description = "La URL completa del repositorio Git.") String urlRepo,
            @ToolParam(description = "La ruta completa del archivo dentro del repositorio.") String filePath,
            @ToolParam(description = "La rama donde se encuentra el archivo.") String rama,
            @ToolParam(description = "Opcional. El hash del commit exacto del que se quiere obtener el archivo. Si es nulo, se usará el último commit de la rama.", required = false) String commit
    ) {
        try {
            Mono<byte[]> contenidoMono;
            if (StringUtils.hasText(commit)) {
                contenidoMono = servicioJGit.extraerContenidoArchivoEnCommit(urlRepo, commit, filePath);
            } else {
                contenidoMono = servicioJGit.extraerContenidoArchivo(urlRepo, rama, filePath);
            }
            
            byte[] contenido = contenidoMono.block();
            return new String(contenido, StandardCharsets.UTF_8);

        } catch (Exception e) {
            return "Error al obtener el archivo: " + e.getMessage();
        }
    }
}
