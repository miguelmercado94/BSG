package com.bsg.soporterag.aplicacion.util;

import java.util.Arrays;
import java.util.HashSet;
import java.util.Set;

/**
 * Utilidad para identificar archivos y directorios excluidos de la indexación RAG.
 */
public final class FiltroArchivosUtil {

    private static final Set<String> EXCLUDED_EXTENSIONS = new HashSet<>(Arrays.asList(
        // Imágenes y Multimedia
        "png", "jpg", "jpeg", "gif", "ico", "svg", "webp", "tiff", "bmp",
        "mp3", "mp4", "wav", "avi", "mkv", "mov", "flv", "wmv", "ogg", "flac",
        // Fuentes
        "woff", "woff2", "ttf", "eot", "otf",
        // Archivos comprimidos y ejecutables
        "zip", "tar", "gz", "rar", "7z", "jar", "war", "ear", "exe", "dll", "so", "dylib", "bin",
        // Compilados e instaladores
        "class", "o", "obj", "msi", "apk", "dmg",
        // Otros no útiles para RAG de soporte
        "pdf", "docx", "xlsx", "pptx", "odt", "ods", "odp"
    ));

    private static final Set<String> EXCLUDED_FOLDERS = new HashSet<>(Arrays.asList(
        "node_modules", "vendor", "target", "bin", "obj", "out", "dist",
        ".mvn", ".gradle", ".idea", ".vscode", "build", "coverage", ".git"
    ));

    private FiltroArchivosUtil() {
        // Clase de utilidad no instanciable
    }

    /**
     * Determina si una ruta de archivo debe ser omitida en la indexación RAG.
     *
     * @param filePath ruta relativa del archivo en el repositorio
     * @return true si el archivo debe ser excluido del embedding; false de lo contrario
     */
    public static boolean debeOmitir(String filePath) {
        if (filePath == null || filePath.isBlank()) {
            return true;
        }

        String pathNormalizado = filePath.replace('\\', '/').trim().toLowerCase();

        // 1. Omitir todos los archivos .ignore
        String nombreArchivo = obtenerNombreArchivo(pathNormalizado);
        if (nombreArchivo.endsWith("ignore") || nombreArchivo.contains(".ignore")) {
            return true;
        }

        // 2. Omitir si la extensión está en la lista de excluidas
        String extension = obtenerExtension(nombreArchivo);
        if (EXCLUDED_EXTENSIONS.contains(extension)) {
            return true;
        }

        // 3. Omitir si alguno de los directorios de la ruta está en la lista de carpetas excluidas
        String[] segmentos = pathNormalizado.split("/");
        for (String segmento : segmentos) {
            if (EXCLUDED_FOLDERS.contains(segmento)) {
                return true;
            }
        }

        return false;
    }

    private static String obtenerNombreArchivo(String path) {
        int index = path.lastIndexOf('/');
        return index >= 0 ? path.substring(index + 1) : path;
    }

    private static String obtenerExtension(String nombreArchivo) {
        int index = nombreArchivo.lastIndexOf('.');
        return index >= 0 && index < nombreArchivo.length() - 1 
            ? nombreArchivo.substring(index + 1) 
            : "";
    }
}
