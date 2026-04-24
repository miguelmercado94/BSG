package com.bsg.docviz.util;

import com.bsg.docviz.dto.TreeNodeDto;

import java.util.List;

public final class FileTreeBuilder {

    private FileTreeBuilder() {
    }

    public static TreeNodeDto fromPaths(List<String> trackedFiles) {
        TreeNodeDto root = new TreeNodeDto();
        root.setFolder("");
        for (String path : trackedFiles) {
            if (path == null || path.isBlank()) {
                continue;
            }
            String normalized = path.replace('\\', '/').trim();
            insert(root, normalized.split("/"));
        }
        return root;
    }

    private static void insert(TreeNodeDto node, String[] segments) {
        if (segments.length == 0) {
            return;
        }
        if (segments.length == 1) {
            String f = segments[0];
            if (!f.isBlank() && !node.getArchivos().contains(f)) {
                node.getArchivos().add(f);
            }
            return;
        }
        String dir = segments[0];
        TreeNodeDto child = findOrCreateChild(node, dir);
        String[] rest = new String[segments.length - 1];
        System.arraycopy(segments, 1, rest, 0, rest.length);
        insert(child, rest);
    }

    private static TreeNodeDto findOrCreateChild(TreeNodeDto parent, String folderName) {
        for (TreeNodeDto f : parent.getFolders()) {
            if (folderName.equals(f.getFolder())) {
                return f;
            }
        }
        TreeNodeDto n = new TreeNodeDto();
        n.setFolder(folderName);
        parent.getFolders().add(n);
        return n;
    }
}
