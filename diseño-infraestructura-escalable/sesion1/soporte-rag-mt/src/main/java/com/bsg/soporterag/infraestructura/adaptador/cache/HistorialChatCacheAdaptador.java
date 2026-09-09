package com.bsg.soporterag.infraestructura.adaptador.cache;

import com.bsg.soporterag.configuracion.CacheRedisPropiedades;
import com.bsg.soporterag.dominio.modelo.MensajeChat;
import com.bsg.soporterag.dominio.puerto.salida.CachePort;
import com.bsg.soporterag.dominio.puerto.salida.HistorialChatCachePort;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import reactor.core.publisher.Mono;

import java.time.Duration;
import java.util.List;

/**
 * Adaptador del historial de chat sobre la cache genérica ({@link CachePort}).
 *
 * Serializa la lista de {@link MensajeChat} a JSON y la guarda con clave por HU
 * (código de tarea). Cuando la cache está deshabilitada, {@link CachePort} usa la
 * implementación no-op y este adaptador degrada de forma segura: obtener devuelve
 * vacío (el caller hace fallback a Mongo) y guardar/invalidar no hacen nada.
 */
@Component
public class HistorialChatCacheAdaptador implements HistorialChatCachePort {

    private static final Logger log = LoggerFactory.getLogger(HistorialChatCacheAdaptador.class);
    private static final TypeReference<List<MensajeChat>> TIPO_LISTA = new TypeReference<>() {};

    private final CachePort cachePort;
    private final CacheRedisPropiedades propiedades;
    private final ObjectMapper objectMapper;

    public HistorialChatCacheAdaptador(
            CachePort cachePort,
            CacheRedisPropiedades propiedades,
            ObjectMapper objectMapper) {
        this.cachePort = cachePort;
        this.propiedades = propiedades;
        this.objectMapper = objectMapper;
    }

    @Override
    public Mono<List<MensajeChat>> obtenerHistorial(String codigoTarea) {
        if (!cachePort.activa()) {
            return Mono.empty();
        }
        return cachePort.obtener(clave(codigoTarea))
                .flatMap(json -> {
                    try {
                        return Mono.just(objectMapper.readValue(json, TIPO_LISTA));
                    } catch (Exception e) {
                        log.warn("No se pudo deserializar historial de cache para tarea={}: {}", codigoTarea, e.getMessage());
                        return Mono.empty();
                    }
                });
    }

    @Override
    public Mono<Void> guardarHistorial(String codigoTarea, List<MensajeChat> mensajes) {
        if (!cachePort.activa()) {
            return Mono.empty();
        }
        try {
            String json = objectMapper.writeValueAsString(mensajes == null ? List.of() : mensajes);
            Duration ttl = Duration.ofSeconds(propiedades.historialTtlSecondsOrDefault());
            return cachePort.guardar(clave(codigoTarea), json, ttl)
                    .doOnSuccess(v -> log.debug("Historial cacheado en Redis para tarea={} ({} mensajes)",
                            codigoTarea, mensajes == null ? 0 : mensajes.size()));
        } catch (Exception e) {
            log.warn("No se pudo serializar historial para cache tarea={}: {}", codigoTarea, e.getMessage());
            return Mono.empty();
        }
    }

    @Override
    public Mono<Void> invalidar(String codigoTarea) {
        if (!cachePort.activa()) {
            return Mono.empty();
        }
        return cachePort.eliminar(clave(codigoTarea));
    }

    private String clave(String codigoTarea) {
        return propiedades.historialKeyPrefixOrDefault() + codigoTarea;
    }
}
