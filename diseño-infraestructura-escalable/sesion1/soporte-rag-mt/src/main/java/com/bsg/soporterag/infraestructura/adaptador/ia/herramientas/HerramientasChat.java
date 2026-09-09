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
    @Tool(name = "consultarPaginaWeb", description = "Consulta una página web y extrae su contenido textual principal para ser analizado.")
    public String consultarPaginaWeb(
            @ToolParam(description = "La URL completa de la página a consultar.") String url
    ) {
        if (!StringUtils.hasText(url)) {
            return "URL no válida";
        }
        String urlTrim = url.trim();
        // Si es una consulta a mvnrepository o maven central, resolver mediante el catálogo oficial
        if (urlTrim.contains("mvnrepository.com") || urlTrim.contains("search.maven.org") || urlTrim.contains("repo1.maven.org")) {
            return resolverConsultaMavenDesdeUrl(urlTrim);
        }

        try {
            org.jsoup.nodes.Document doc = Jsoup.connect(urlTrim)
                    .userAgent("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36")
                    .header("Accept", "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8")
                    .header("Accept-Language", "es-ES,es;q=0.9,en;q=0.8")
                    .timeout(12000)
                    .followRedirects(true)
                    .get();
            String text = doc.body() != null ? doc.body().text() : doc.text();
            if (text != null && text.length() > 8000) {
                return text.substring(0, 8000) + "... [contenido truncado]";
            }
            return text != null ? text : "La página no contiene texto visible.";
        } catch (org.jsoup.HttpStatusException e) {
            return "No se pudo acceder a la URL (" + urlTrim + ") debido a restricciones del servidor web (HTTP " + e.getStatusCode() + "). Si buscas dependencias Maven, utiliza la herramienta 'consultarDependenciasMaven'.";
        } catch (IOException e) {
            return "Error al intentar acceder a la URL: " + e.getMessage() + ". Si buscas dependencias Maven, utiliza la herramienta 'consultarDependenciasMaven'.";
        } catch (Exception e) {
            return "Ocurrió un error inesperado al procesar la página: " + e.getMessage();
        }
    }

    @Tool(name = "consultarDependenciasMaven", description = "Consulta en tiempo real el repositorio oficial de Maven Central para obtener las versiones más recientes y estables de dependencias y librerías Java (ej: 'software.amazon.awssdk:dynamodb', 'com.amazonaws:aws-java-sdk-sqs', 'software.amazon.awssdk:bom', 'dynamodb', etc.).")
    public String consultarDependenciasMaven(
            @ToolParam(description = "Identificador de la dependencia: coordenadas groupId:artifactId (ej: 'software.amazon.awssdk:dynamodb') o nombre del artefacto (ej: 'aws-java-sdk-sqs', 'dynamodb').") String dependencia
    ) {
        if (!StringUtils.hasText(dependencia)) {
            return "Por favor especifica el nombre o coordenadas de la dependencia a consultar.";
        }
        return resolverYConsultarMaven(dependencia.trim());
    }

    private String resolverConsultaMavenDesdeUrl(String url) {
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
               Para consultar versiones exactas y actualizadas de cualquier dependencia, utiliza la herramienta 'consultarDependenciasMaven' indicando las coordenadas (por ejemplo: 'software.amazon.awssdk:dynamodb', 'com.amazonaws:aws-java-sdk-sqs', 'software.amazon.awssdk:bom').
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
