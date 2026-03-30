package com.bsg.docviz.service;

import com.bsg.docviz.dto.TreeNodeDto;

import java.nio.file.Path;
import java.util.Optional;

public class UserRepositoryState {

    private volatile boolean connected;
    private Path repositoryRoot;
    private Path managedCloneRoot;
    private String revisionSpec = "HEAD";
    private TreeNodeDto treeRoot;
    private String rootFolderLabel = "";
    /** Vista previa / RAG: independiente de la ingesta para que no compitan por los 100 MiB. */
    private final FileContentCache viewerContentCache = new FileContentCache();
    /** Prefetch e ingesta a Pinecone. */
    private final FileContentCache ingestContentCache = new FileContentCache();

    public boolean isConnected() {
        return connected;
    }

    public Path getRepositoryRoot() {
        return repositoryRoot;
    }

    public Path getManagedCloneRoot() {
        return managedCloneRoot;
    }

    /** Clon bajo context-masters (HTTPS); se puede borrar el working tree archivo a archivo sin tocar un repo local del usuario. */
    public boolean isEphemeralManagedClone() {
        return managedCloneRoot != null;
    }

    public Optional<Path> drainManagedCloneRoot() {
        Path p = managedCloneRoot;
        managedCloneRoot = null;
        return Optional.ofNullable(p);
    }

    public String getRevisionSpec() {
        return revisionSpec;
    }

    public TreeNodeDto getTreeRoot() {
        return treeRoot;
    }

    public String getRootFolderLabel() {
        return rootFolderLabel;
    }

    public FileContentCache getViewerContentCache() {
        return viewerContentCache;
    }

    public FileContentCache getIngestContentCache() {
        return ingestContentCache;
    }

    public void disconnect() {
        connected = false;
        repositoryRoot = null;
        managedCloneRoot = null;
        treeRoot = null;
        revisionSpec = "HEAD";
        rootFolderLabel = "";
        viewerContentCache.clear();
        ingestContentCache.clear();
    }

    public void setConnected(Path root, Path managedClone, String rev, TreeNodeDto tree, String rootFolderLabel) {
        this.repositoryRoot = root;
        this.managedCloneRoot = managedClone;
        this.revisionSpec = rev;
        this.treeRoot = tree;
        this.rootFolderLabel = rootFolderLabel != null ? rootFolderLabel : "";
        this.connected = true;
    }
}
