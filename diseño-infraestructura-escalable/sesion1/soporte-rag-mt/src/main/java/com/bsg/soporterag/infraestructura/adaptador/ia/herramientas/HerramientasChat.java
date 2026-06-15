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
        try {
            org.jsoup.nodes.Document doc = Jsoup.connect(url).get();
            return doc.body().text();
        } catch (IOException e) {
            return "Error al intentar acceder a la URL: " + e.getMessage();
        } catch (Exception e) {
            return "Ocurrió un error inesperado al procesar la página: " + e.getMessage();
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
