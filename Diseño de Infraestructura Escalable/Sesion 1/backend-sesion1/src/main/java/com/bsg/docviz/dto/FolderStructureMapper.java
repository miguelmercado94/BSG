package com.bsg.docviz.dto;

import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;

public final class FolderStructureMapper {

    private FolderStructureMapper() {
    }

    public static FolderStructureDto fromTreeRoot(TreeNodeDto root, String rootFolderLabel, Path repositoryRoot) {
        if (root == null) {
            return null;
        }
        return mapNode(root);
    }

    private static FolderStructureDto mapNode(TreeNodeDto n) {
        FolderStructureDto d = new FolderStructureDto();
        d.setFolder(n.getFolder() != null ? n.getFolder() : "");
        d.setArchivos(new ArrayList<>(n.getArchivos() != null ? n.getArchivos() : List.of()));
        List<FolderStructureDto> subs = new ArrayList<>();
        if (n.getFolders() != null) {
            for (TreeNodeDto c : n.getFolders()) {
                subs.add(mapNode(c));
            }
        }
        d.setFolders(subs);
        return d;
    }

    public static void ensureRootFolderName(FolderStructureDto directory, Path root) {
        if (directory != null && (directory.getFolder() == null || directory.getFolder().isBlank()) && root != null) {
            Path fn = root.getFileName();
            if (fn != null) {
                directory.setFolder(fn.toString());
            }
        }
    }
}
