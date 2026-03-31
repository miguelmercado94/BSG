package com.bsg.docviz.service;

import com.bsg.docviz.config.DocvizProperties;
import com.bsg.docviz.config.VectorProperties;
import com.bsg.docviz.security.CurrentUser;
import com.bsg.docviz.vector.PineconeVectorClient;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.nio.file.FileVisitResult;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.SimpleFileVisitor;
import java.nio.file.attribute.BasicFileAttributes;

/**
 * Cierra la sesión DocViz: borra vectores Pinecone del namespace del repo actual, la carpeta
 * {@code context-masters/&lt;usuario&gt;/} y el estado en memoria.
 */
@Service
public class SessionLogoutService {

    private static final Logger log = LoggerFactory.getLogger(SessionLogoutService.class);

    private final SessionRegistry sessionRegistry;
    private final DocvizProperties docvizProperties;
    private final VectorProperties vectorProperties;
    private final PineconeVectorClient pineconeVectorClient;

    public SessionLogoutService(
            SessionRegistry sessionRegistry,
            DocvizProperties docvizProperties,
            VectorProperties vectorProperties,
            PineconeVectorClient pineconeVectorClient
    ) {
        this.sessionRegistry = sessionRegistry;
        this.docvizProperties = docvizProperties;
        this.vectorProperties = vectorProperties;
        this.pineconeVectorClient = pineconeVectorClient;
    }

    public void logout() {
        String userKey = CurrentUser.require();
        UserRepositoryState st = sessionRegistry.getIfPresent(userKey);

        if (st != null && vectorProperties.isEnabled() && st.isConnected()) {
            String ns = namespaceForSession(st, userKey);
            try {
                pineconeVectorClient.deleteAllVectorsInNamespace(pineconeVectorClient.getIndexHost(), ns);
            } catch (RuntimeException e) {
                log.warn("No se pudo vaciar Pinecone namespace {}: {}", ns, e.getMessage());
            }
        }

        if (st != null) {
            st.disconnect();
        }
        sessionRegistry.remove(userKey);

        Path userDir = docvizProperties.resolveRootDirectory().resolve(userKey);
        try {
            deleteRecursively(userDir);
        } catch (IOException e) {
            log.warn("No se pudo borrar carpeta de usuario {}: {}", userDir, e.getMessage());
        }
    }

    private static String namespaceForSession(UserRepositoryState st, String sanitizedUser) {
        String label = st.getRootFolderLabel() != null && !st.getRootFolderLabel().isBlank()
                ? st.getRootFolderLabel()
                : "repo";
        return sanitizedUser + "__" + label.replaceAll("[^a-zA-Z0-9._-]", "_");
    }

    private static void deleteRecursively(Path root) throws IOException {
        if (root == null || !Files.exists(root)) {
            return;
        }
        Files.walkFileTree(root, new SimpleFileVisitor<>() {
            @Override
            public FileVisitResult visitFile(Path file, BasicFileAttributes attrs) throws IOException {
                Files.deleteIfExists(file);
                return FileVisitResult.CONTINUE;
            }

            @Override
            public FileVisitResult postVisitDirectory(Path dir, IOException exc) throws IOException {
                Files.deleteIfExists(dir);
                return FileVisitResult.CONTINUE;
            }
        });
    }
}
