package com.bsg.docviz.util;

/**
 * Alinea rutas del modelo/UI (p. ej. {@code findu/docker-compose.yml}) con el árbol Git del clon, donde la raíz del
 * repositorio ya puede ser la carpeta del proyecto (sin prefijo {@code findu/}).
 */
public final class WorkAreaRepoPathResolver {

    private WorkAreaRepoPathResolver() {}

    /**
     * Si {@code rel} empieza por {@code rootFolderLabel/} (etiqueta del explorador), devuelve la ruta relativa al
     * commit (p. ej. {@code docker-compose.yml}). Si no hay etiqueta o no coincide, devuelve {@code rel} sin cambiar.
     */
    public static String stripUiRootFolderPrefix(String rel, String rootFolderLabel) {
        if (rel == null || rel.isBlank()) {
            return rel;
        }
        String r = WorkAreaDraftPathBuilder.normalizeRelPath(rel);
        if (rootFolderLabel == null || rootFolderLabel.isBlank()) {
            return r;
        }
        String label = rootFolderLabel.replace('\\', '/').trim();
        if (label.isEmpty()) {
            return r;
        }
        String prefix = label + "/";
        if (r.startsWith(prefix)) {
            return r.substring(prefix.length());
        }
        return r;
    }
}
