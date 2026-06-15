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
    private static final int RESUMEN_CADA_N_MENSAJES = 20;
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

    public InteractuarChatCasoUsoImpl(
            TareaServicio tareaServicio,
            RepositorioServicio repositorioServicio,
            TagServicio tagServicio,
            ServicioBusquedaVectorial servicioBusquedaVectorial,
            ChatServicio chatServicio,
            VectorPropiedades vectorPropiedades,
            TareaDtoMapper tareaDtoMapper, 
            ServicioJGit servicioJGit, 
            ServicioBucketS3 servicioBucketS3) {
        this.tareaServicio = tareaServicio;
        this.repositorioServicio = repositorioServicio;
        this.tagServicio = tagServicio;
        this.servicioBusquedaVectorial = servicioBusquedaVectorial;
        this.chatServicio = chatServicio;
        this.vectorPropiedades = vectorPropiedades;
        this.tareaDtoMapper = tareaDtoMapper;
        this.servicioJGit = servicioJGit;
        this.servicioBucketS3 = servicioBucketS3;
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

                    // 2. Analizar intención
                    return chatServicio.analizar(codigoTarea + "_analisis", request.getMensaje(), "")
                            .flatMap(analisis -> {
                                
                                Mono<String> respuestaIAMono;
                                if (analisis.isRequiereProcesamientoProfundo() || !referencias.isEmpty()) {
                                    
                                    Mono<String> contextoRagMono = (analisis.isRequiereRag() || !referencias.isEmpty())
                                            ? servicioBusquedaVectorial.buscarContexto(tarea.getUrlRepo(), request.getMensaje(), vectorPropiedades.ragTopK())
                                                .map(CoincidenciaVectorial::texto)
                                                .collect(Collectors.joining("\n---\n"))
                                                .defaultIfEmpty("No se encontró información en la base de datos de conocimiento.")
                                            : Mono.just("");
                                    
                                    String contextoHistorial = analisis.isRequiereHistorialChat() ? construirContextoHistorial(tarea) : "";

                                    respuestaIAMono = Mono.zip(contextoRagMono, contextoDeReferencias)
                                            .flatMap(tuple -> {
                                                String contextoFinal = String.join("\n\n", tuple.getT1(), tuple.getT2(), contextoHistorial).trim();
                                                return chatServicio.conversar(codigoTarea, request.getMensaje(), contextoFinal);
                                            });

                                } else {
                                    respuestaIAMono = chatServicio.conversarDirecto(codigoTarea, request.getMensaje());
                                }

                                return respuestaIAMono.flatMap(respuestaIA -> 
                                        guardarYProcesarResumen(tarea, request.getMensaje(), respuestaIA));
                            });
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
        return Flux.fromIterable(referencias)
                .flatMap(ref -> {
                    if ("repo".equals(ref.tipo())) {
                        return servicioJGit.extraerContenidoArchivo(tarea.getUrlRepo(), null, ref.ruta()) // Asume rama principal
                                .map(bytes -> new String(bytes, StandardCharsets.UTF_8))
                                .map(contenido -> "Contexto del archivo de repositorio '" + ref.ruta() + "':\n" + contenido);
                    } else if ("soporte".equals(ref.tipo())) {
                        return servicioBucketS3.obtenerArchivo(RolBucketS3.WORKAREA, ref.ruta())
                                .map(bytes -> new String(bytes, StandardCharsets.UTF_8))
                                .map(contenido -> "Contexto del documento de soporte '" + ref.ruta() + "':\n" + contenido);
                    }
                    return Mono.empty();
                })
                .collect(Collectors.joining("\n\n"))
                .defaultIfEmpty("");
    }

    private record ReferenciaContexto(String tipo, String ruta) {}

    // ... resto de métodos ...
    private String construirContextoHistorial(Tarea tarea) {
        String resumenPrevio = tarea.getResumen() != null ? "Resumen de la conversación hasta ahora:\n" + tarea.getResumen() + "\n\n" : "";
        
        List<MensajeChat> mensajes = tarea.getMsgChat();
        if (mensajes == null || mensajes.isEmpty()) {
            return resumenPrevio;
        }

        int mensajesNoResumidosCount = mensajes.size() % RESUMEN_CADA_N_MENSAJES;
        String mensajesRecientes = "";
        if (mensajesNoResumidosCount > 0) {
            int inicio = mensajes.size() - mensajesNoResumidosCount;
            mensajesRecientes = "Últimos mensajes (no resumidos):\n" + mensajes.subList(inicio, mensajes.size()).stream()
                    .map(msg -> "Usuario: " + msg.getTextoEntrada() + "\nAsistente: " + msg.getTextoRespuesta())
                    .collect(Collectors.joining("\n"));
        }
        return (resumenPrevio + mensajesRecientes).trim();
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

    private Mono<MensajeChat> guardarYProcesarResumen(Tarea tarea, String mensajeUsuario, String respuestaIA) {
        MensajeChat nuevoMensaje = new MensajeChat(
                mensajeUsuario, null, respuestaIA, LocalDate.now(), Instant.now());

        return tareaServicio.agregarMensajeChat(tarea.getCodigoTarea(), nuevoMensaje)
                .then(tareaServicio.obtenerPorCodigo(tarea.getCodigoTarea()))
                .flatMap(tareaActualizada -> {
                    int totalMensajes = tareaActualizada.getMsgChat().size();
                    if (totalMensajes > 0 && totalMensajes % RESUMEN_CADA_N_MENSAJES == 0) {
                        log.info("Disparando generación de resumen para la tarea {} al alcanzar {} mensajes.", tarea.getCodigoTarea(), totalMensajes);
                        dispararResumen(tareaActualizada).subscribe();
                    }
                    return Mono.just(nuevoMensaje);
                });
    }

    private Mono<Void> dispararResumen(Tarea tarea) {
        String contextoResumen = construirContextoHistorial(tarea);
        if (contextoResumen.isEmpty()) {
            return Mono.empty();
        }
        return chatServicio.resumirConversacion(tarea.getCodigoTarea() + "_resumen", contextoResumen)
                .flatMap(nuevoResumen -> tareaServicio.actualizarResumen(tarea.getCodigoTarea(), nuevoResumen))
                .then();
    }
}
