package com.bsg.docviz.util;

import com.bsg.docviz.dto.TreeNodeDto;

import java.util.Optional;

/** Busca la primera ruta relativa que termina en un nombre de archivo (p. ej. CustomerRest.java). */
public final class RepoTreePathFinder {

    private RepoTreePathFinder() {}

    public static Optional<String> findFirstPathByBasename(TreeNodeDto root, String basename) {
        if (root == null || basename == null || basename.isBlank()) {
            return Optional.empty();
        }
        String b = basename.trim();
        return walk(root, "", b);
    }

    private static Optional<String> walk(TreeNodeDto node, String prefix, String basename) {
        for (String f : node.getArchivos()) {
            if (basename.equals(f)) {
                return Optional.of(prefix.isEmpty() ? f : prefix + "/" + f);
            }
        }
        for (TreeNodeDto sub : node.getFolders()) {
            String next = prefix.isEmpty() ? sub.getFolder() : prefix + "/" + sub.getFolder();
            Optional<String> r = walk(sub, next, basename);
            if (r.isPresent()) {
                return r;
            }
        }
        return Optional.empty();
    }
}
