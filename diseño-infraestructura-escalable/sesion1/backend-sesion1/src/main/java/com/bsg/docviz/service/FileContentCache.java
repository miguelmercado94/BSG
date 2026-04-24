package com.bsg.docviz.service;

import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Caché de contenido en RAM por ruta relativa: no se descarga el repo entero, solo archivos bajo demanda.
 * Por sesión hay dos instancias en {@link UserRepositoryState}: visualización/RAG vs ingesta Pinecone,
 * cada una con su propio techo de 100 MiB para que no compitan.
 * <p>
 * Límites: un archivo puede ocupar hasta {@link #MAX_SINGLE_FILE_BYTES}; la suma de todos los
 * archivos en caché no supera {@link #MAX_CACHE_TOTAL_BYTES}. Al insertar uno nuevo, si no cabe,
 * se expulsan primero los entries más pesados hasta liberar espacio suficiente: prioridad para el
 * archivo que se está cargando o visualizando. {@link LinkedHashMap} en modo acceso actualiza el
 * orden en {@link #get} (útil si más adelante se mezcla con otra política).
 * <p>
 * Los bytes en disco tras {@code git checkout} se borran aparte en clones efímeros (HTTPS).
 */
public class FileContentCache {

    /** Tamaño máximo de un solo blob en caché (también usado para rechazar descargas demasiado grandes). */
    public static final long MAX_SINGLE_FILE_BYTES = 100L * 1024 * 1024;

    /** Suma máxima de bytes de todos los archivos cacheados a la vez. */
    public static final long MAX_CACHE_TOTAL_BYTES = 100L * 1024 * 1024;

    private final Object lock = new Object();
    private final LinkedHashMap<String, byte[]> byKey = new LinkedHashMap<>(8, 0.75f, true);

    public void clear() {
        synchronized (lock) {
            byKey.clear();
        }
    }

    /**
     * Inserta o reemplaza; si hace falta espacio, elimina entradas empezando por la de mayor tamaño
     * hasta que quepa {@code data} (sin superar {@link #MAX_CACHE_TOTAL_BYTES}).
     */
    public void put(String key, byte[] data) {
        if (key == null || data == null || data.length > MAX_SINGLE_FILE_BYTES) {
            return;
        }
        synchronized (lock) {
            byte[] previous = byKey.remove(key);
            long total = sumBytes();
            if (previous != null) {
                total -= previous.length;
            }
            while (total + data.length > MAX_CACHE_TOTAL_BYTES && !byKey.isEmpty()) {
                Map.Entry<String, byte[]> heaviest = findHeaviestEntry();
                if (heaviest == null) {
                    break;
                }
                total -= heaviest.getValue().length;
                byKey.remove(heaviest.getKey());
            }
            if (total + data.length > MAX_CACHE_TOTAL_BYTES) {
                return;
            }
            byKey.put(key, data);
        }
    }

    private long sumBytes() {
        long s = 0;
        for (byte[] b : byKey.values()) {
            s += b.length;
        }
        return s;
    }

    private Map.Entry<String, byte[]> findHeaviestEntry() {
        Map.Entry<String, byte[]> best = null;
        int max = -1;
        for (Map.Entry<String, byte[]> e : byKey.entrySet()) {
            int len = e.getValue().length;
            if (len > max) {
                max = len;
                best = e;
            }
        }
        return best;
    }

    public byte[] get(String key) {
        synchronized (lock) {
            return byKey.get(key);
        }
    }

    public void remove(String key) {
        synchronized (lock) {
            byKey.remove(key);
        }
    }
}
