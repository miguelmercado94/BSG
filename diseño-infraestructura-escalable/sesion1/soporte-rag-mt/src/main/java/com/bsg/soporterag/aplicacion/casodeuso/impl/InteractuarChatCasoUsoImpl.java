package com.bsg.soporterag.aplicacion.casodeuso.impl;

import com.bsg.soporterag.aplicacion.casodeuso.InteractuarChatCasoUso;
import com.bsg.soporterag.aplicacion.dto.request.ChatRequestDto;
import com.bsg.soporterag.aplicacion.dto.response.MensajeChatDto;
import com.bsg.soporterag.aplicacion.mapperdto.TareaDtoMapper;
import com.bsg.soporterag.aplicacion.servicio.*;
import com.bsg.soporterag.configuracion.VectorPropiedades;
import com.bsg.soporterag.dominio.modelo.*;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Collectors;

@Service
public class InteractuarChatCasoUsoImpl implements InteractuarChatCasoUso {

    private static final Logger log = LoggerFactory.getLogger(InteractuarChatCasoUsoImpl.class);
    private static final int MAX_MENSAJES_HISTORIAL = 20;
    private static final Pattern REFERENCIA_PATTERN = Pattern.compile("\\[@(repo|soporte)/([^\\]]+)\\]");


    private final TareaServicio tareaServicio;
    private final RepositorioServicio repositorioServicio;
    private final TagServicio tagServicio;
    private final ServicioBusquedaVectorial servicioBusquedaVectorial;
    private final ChatServicio chatServicio;
    private final VectorPropiedades vectorPropiedades;
    private final TareaDtoMapper tareaDtoMapper;
    private final ServicioJGit servicioJGit;
    private final ServicioBucketS3 servicioBucketS3;
    private final com.bsg.soporterag.dominio.puerto.salida.AlmacenVectorialPort almacenVectorialPort;
    private final com.bsg.soporterag.dominio.puerto.salida.HistorialChatCachePort historialChatCachePort;

    public InteractuarChatCasoUsoImpl(
            TareaServicio tareaServicio,
            RepositorioServicio repositorioServicio,
            TagServicio tagServicio,
            ServicioBusquedaVectorial servicioBusquedaVectorial,
            ChatServicio chatServicio,
            VectorPropiedades vectorPropiedades,
            TareaDtoMapper tareaDtoMapper, 
            ServicioJGit servicioJGit, 
            ServicioBucketS3 servicioBucketS3,
            com.bsg.soporterag.dominio.puerto.salida.AlmacenVectorialPort almacenVectorialPort,
            com.bsg.soporterag.dominio.puerto.salida.HistorialChatCachePort historialChatCachePort) {
        this.tareaServicio = tareaServicio;
        this.repositorioServicio = repositorioServicio;
        this.tagServicio = tagServicio;
        this.servicioBusquedaVectorial = servicioBusquedaVectorial;
        this.chatServicio = chatServicio;
        this.vectorPropiedades = vectorPropiedades;
        this.tareaDtoMapper = tareaDtoMapper;
        this.servicioJGit = servicioJGit;
        this.servicioBucketS3 = servicioBucketS3;
        this.almacenVectorialPort = almacenVectorialPort;
        this.historialChatCachePort = historialChatCachePort;
    }

    @Override
    public Mono<MensajeChatDto> conversar(String codigoTarea, ChatRequestDto request) {
        if (!StringUtils.hasText(request.getMensaje())) {
            return Mono.error(new IllegalArgumentException("El mensaje no puede estar vacío"));
        }

        return tareaServicio.obtenerPorCodigo(codigoTarea)
                .flatMap(tarea -> {
                    if (tarea.getEstadoTarea() != EstadoTarea.INICIADA) {
                        return Mono.error(new IllegalStateException("Solo se puede chatear con tareas en estado INICIADA."));
                    }

                    // 1. Pre-procesamiento: Extraer referencias explícitas del mensaje
                    List<ReferenciaContexto> referencias = extraerReferencias(request.getMensaje());
                    
                    Mono<String> contextoDeReferencias = !referencias.isEmpty()
                            ? construirContextoDesdeReferencias(tarea, referencias)
                            : Mono.just("");

                    // 2. Analizar intención con herramientas y URLs disponibles
                    return obtenerHerramientasDisponibles(tarea)
                            .flatMap(tools -> chatServicio.analizar(codigoTarea + "_analisis", request.getMensaje(), tools)
                                    .flatMap(analisis -> {
                                        
                                        Mono<String> respuestaIAMono;
                                        if (analisis.isRequiereProcesamientoProfundo() || !referencias.isEmpty() || StringUtils.hasText(tools)) {
                                            
                                            Mono<String> contextoRagMono = (analisis.isRequiereRag() || !referencias.isEmpty())
                                                    ? servicioBusquedaVectorial.buscarContexto(tarea.getUrlRepo(), request.getMensaje(), vectorPropiedades.ragTopK())
                                                        .map(CoincidenciaVectorial::texto)
                                                        .collect(Collectors.joining("\n---\n"))
                                                        .defaultIfEmpty("No se encontró información en la base de datos de conocimiento.")
                                                    : Mono.just("");
                                            
                                            Mono<String> contextoHistorialMono = analisis.isRequiereHistorialChat()
                                                    ? construirContextoHistorial(tarea)
                                                    : Mono.just("");

                                            respuestaIAMono = Mono.zip(contextoRagMono, contextoDeReferencias, contextoHistorialMono)
                                                    .flatMap(tuple -> {
                                                        String contextoTools = StringUtils.hasText(tools)
                                                                ? "Herramientas y documentación web disponibles para consulta en línea:\n" + tools
                                                                : "";
                                                        String contextoFinal = java.util.stream.Stream.of(tuple.getT1(), tuple.getT2(), tuple.getT3(), contextoTools)
                                                                .filter(s -> s != null && !s.isBlank())
                                                                .collect(Collectors.joining("\n\n"));
                                                        return chatServicio.conversar(codigoTarea, request.getMensaje(), contextoFinal);
                                                    });

                                        } else {
                                            respuestaIAMono = chatServicio.conversarDirecto(codigoTarea, request.getMensaje());
                                        }

                                        return respuestaIAMono.flatMap(respuestaIA -> 
                                                guardarMensaje(tarea, request.getMensaje(), respuestaIA));
                                    }));
                })
                .map(tareaDtoMapper::aDto);
    }

    private List<ReferenciaContexto> extraerReferencias(String mensaje) {
        List<ReferenciaContexto> referencias = new ArrayList<>();
        Matcher matcher = REFERENCIA_PATTERN.matcher(mensaje);
        while (matcher.find()) {
            referencias.add(new ReferenciaContexto(matcher.group(1), matcher.group(2)));
        }
        return referencias;
    }

    private Mono<String> construirContextoDesdeReferencias(Tarea tarea, List<ReferenciaContexto> referencias) {
        return repositorioServicio.obtenerRepo(tarea.getUrlRepo())
                .flatMap(repo -> {
                    String ns = repo.getNamespace() != null ? repo.getNamespace() : tarea.getUrlRepo();
                    return Flux.fromIterable(referencias)
                            .flatMap(ref -> {
                                FuenteRag fuente = "soporte".equals(ref.tipo()) ? FuenteRag.SOPORTE : FuenteRag.GIT;
                                // Buscar todos los chunks del archivo embebido en pgvector
                                return almacenVectorialPort.buscarPorDocumento(fuente, ns, ref.ruta())
                                        .map(CoincidenciaVectorial::texto)
                                        .collect(Collectors.joining("\n"))
                                        .filter(contenido -> !contenido.isBlank())
                                        .map(contenido -> "Contenido de '" + ref.ruta() + "':\n" + contenido)
                                        .defaultIfEmpty("No se encontraron chunks embebidos para '" + ref.ruta() + "'")
                                        .onErrorResume(e -> {
                                            log.warn("Error buscando chunks para ref={}: {}", ref.ruta(), e.getMessage());
                                            return Mono.just("Error al buscar '" + ref.ruta() + "': " + e.getMessage());
                                        });
                            })
                            .collect(Collectors.joining("\n\n"))
                            .defaultIfEmpty("");
                })
                .defaultIfEmpty("");
    }

    private record ReferenciaContexto(String tipo, String ruta) {}

    /**
     * Construye el contexto histórico para el LLM leyendo primero de Redis (cache por HU).
     * Si hay miss (o Redis apagado), cae a MongoDB usando el historial ya cargado en la tarea
     * y rehidrata la cache para las siguientes consultas (read-through).
     */
    private Mono<String> construirContextoHistorial(Tarea tarea) {
        return historialChatCachePort.obtenerHistorial(tarea.getCodigoTarea())
                .doOnNext(m -> log.debug("Historial de tarea={} servido desde cache Redis", tarea.getCodigoTarea()))
                .switchIfEmpty(Mono.defer(() -> {
                    List<MensajeChat> mensajesBd = tarea.getMsgChat() != null ? tarea.getMsgChat() : List.of();
                    // Rehidrata la cache con lo que hay en BD (no bloquea la respuesta).
                    return historialChatCachePort.guardarHistorial(tarea.getCodigoTarea(), mensajesBd)
                            .thenReturn(mensajesBd);
                }))
                .map(this::formatearHistorial);
    }

    private String formatearHistorial(List<MensajeChat> mensajes) {
        if (mensajes == null || mensajes.isEmpty()) {
            return "";
        }
        int inicio = Math.max(0, mensajes.size() - MAX_MENSAJES_HISTORIAL);
        String mensajesRecientes = "Últimos mensajes:\n" + mensajes.subList(inicio, mensajes.size()).stream()
                .map(msg -> "Usuario: " + msg.getTextoEntrada() + "\nAsistente: " + msg.getTextoRespuesta())
                .collect(Collectors.joining("\n"));
        return mensajesRecientes.trim();
    }

    private Mono<String> obtenerHerramientasDisponibles(Tarea tarea) {
        return repositorioServicio.obtenerRepo(tarea.getUrlRepo())
                .flatMap(repo -> {
                    if (repo.getTags() == null || repo.getTags().isEmpty()) {
                        return Mono.just("");
                    }
                    return tagServicio.obtenerTagsPorNombres(repo.getTags().toArray(new String[0]))
                            .filter(Tag::isHabilitado)
                            .flatMapIterable(Tag::getUrlToolTag)
                            .map(tool -> tool.getUrlTool() + " - " + tool.getContextoUrl())
                            .collect(Collectors.joining("\n"))
                            .defaultIfEmpty("");
                });
    }

    private Mono<MensajeChat> guardarMensaje(Tarea tarea, String mensajeUsuario, String respuestaIA) {
        MensajeChat nuevoMensaje = new MensajeChat(
                mensajeUsuario, null, respuestaIA, LocalDate.now(), Instant.now());

        // Write-through: 1) persistir en BD (fuente de verdad) 2) refrescar cache Redis del historial por HU.
        return tareaServicio.agregarMensajeChat(tarea.getCodigoTarea(), nuevoMensaje)
                .then(tareaServicio.obtenerPorCodigo(tarea.getCodigoTarea()))
                .flatMap(tareaActualizada -> historialChatCachePort
                        .guardarHistorial(tareaActualizada.getCodigoTarea(),
                                tareaActualizada.getMsgChat() != null ? tareaActualizada.getMsgChat() : List.of())
                        .onErrorResume(e -> {
                            log.warn("No se pudo refrescar cache de historial para tarea={}: {}",
                                    tarea.getCodigoTarea(), e.getMessage());
                            return Mono.empty();
                        }))
                .thenReturn(nuevoMensaje);
    }

    @Override
    public Flux<String> conversarStream(String codigoTarea, ChatRequestDto request) {
        if (!StringUtils.hasText(request.getMensaje())) {
            return Flux.error(new IllegalArgumentException("El mensaje no puede estar vacío"));
        }

        return tareaServicio.obtenerPorCodigo(codigoTarea)
                .flatMapMany(tarea -> {
                    if (tarea.getEstadoTarea() != EstadoTarea.INICIADA) {
                        return Flux.error(new IllegalStateException("Solo se puede chatear con tareas en estado INICIADA."));
                    }

                    // 1. Extraer referencias explícitas @[repo:...] y @[soporte:...]
                    List<ReferenciaContexto> referencias = extraerReferencias(request.getMensaje());
                    Mono<String> contextoDeReferencias = !referencias.isEmpty()
                            ? construirContextoDesdeReferencias(tarea, referencias)
                            : Mono.just("");

                    // 2. Búsqueda RAG en pgvector usando el repo asociado a la tarea
                    Mono<String> contextoRagMono = servicioBusquedaVectorial
                            .buscarContexto(tarea.getUrlRepo(), request.getMensaje(), vectorPropiedades.ragTopK())
                            .map(CoincidenciaVectorial::texto)
                            .collect(Collectors.joining("\n---\n"))
                            .defaultIfEmpty("");

                    // 3. Historial servido desde Redis (cache por HU) con fallback a Mongo
                    Mono<String> contextoHistorialMono = construirContextoHistorial(tarea);

                    // 4. Herramientas y tags disponibles
                    Mono<String> toolsMono = obtenerHerramientasDisponibles(tarea);

                    // 5. Combinar todo: referencias + RAG + historial + herramientas → stream a GPT
                    return Mono.zip(contextoRagMono, contextoDeReferencias, contextoHistorialMono, toolsMono).flatMapMany(tuple -> {
                        String tools = tuple.getT4();
                        String contextoTools = StringUtils.hasText(tools)
                                ? "Herramientas y documentación web disponibles para consulta en línea:\n" + tools
                                : "";
                        String contextoFinal = java.util.stream.Stream.of(tuple.getT1(), tuple.getT2(), tuple.getT3(), contextoTools)
                                .filter(s -> s != null && !s.isBlank())
                                .collect(Collectors.joining("\n\n"));

                        Flux<String> tokenStream = contextoFinal.isEmpty()
                                ? chatServicio.conversarDirectoStream(codigoTarea, request.getMensaje())
                                : chatServicio.conversarStream(codigoTarea, request.getMensaje(), contextoFinal);

                        StringBuilder respuestaCompleta = new StringBuilder();

                        return tokenStream
                                .doOnNext(respuestaCompleta::append)
                                .doOnError(err -> log.error("Error en tokenStream para tarea={}", codigoTarea, err))
                                .doOnComplete(() -> {
                                    guardarMensaje(tarea, request.getMensaje(), respuestaCompleta.toString())
                                            .subscribe(
                                                    msg -> log.debug("Mensaje persistido para tarea {}", codigoTarea),
                                                    err -> log.error("Error persistiendo mensaje para tarea {}: {}", codigoTarea, err.getMessage())
                                            );
                                });
                    });
                });
    }

    @Override
    public Mono<String> obtenerHistorialFormateado(String codigoTarea) {
        return tareaServicio.obtenerPorCodigo(codigoTarea)
                .flatMap(this::construirContextoHistorial)
                .defaultIfEmpty("");
    }
}
