package com.bsg.docviz.config;

import com.bsg.docviz.dto.GitConnectRequest;
import com.bsg.docviz.dto.GitConnectionMode;
import com.bsg.docviz.security.CurrentUser;
import com.bsg.docviz.application.port.output.GitRepositoryPort;
import com.bsg.docviz.application.port.output.SessionRegistryPort;
import com.bsg.docviz.vector.VectorIngestService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.context.annotation.Profile;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;

/**
 * Opcional: al arrancar la app desde el {@code main}, ejecuta el mismo flujo que la UI
 * (conexión Git → ingesta a pgvector/Pinecone). Activar con {@code docviz.bootstrap.enabled=true}
 * y {@code docviz.bootstrap.git-url=...}.
 */
@Component
@Profile("!test")
@Order(Ordered.HIGHEST_PRECEDENCE + 10)
public class DocvizGitBootstrapRunner implements ApplicationRunner {

    private static final Logger log = LoggerFactory.getLogger(DocvizGitBootstrapRunner.class);

    private final DocvizBootstrapProperties bootstrap;
    private final VectorProperties vectorProperties;
    private final GitRepositoryPort gitRepositoryService;
    private final VectorIngestService vectorIngestService;
    private final SessionRegistryPort sessionRegistry;

    public DocvizGitBootstrapRunner(
            DocvizBootstrapProperties bootstrap,
            VectorProperties vectorProperties,
            GitRepositoryPort gitRepositoryService,
            VectorIngestService vectorIngestService,
            SessionRegistryPort sessionRegistry) {
        this.bootstrap = bootstrap;
        this.vectorProperties = vectorProperties;
        this.gitRepositoryService = gitRepositoryService;
        this.vectorIngestService = vectorIngestService;
        this.sessionRegistry = sessionRegistry;
    }

    @Override
    public void run(ApplicationArguments args) {
        if (!bootstrap.isEnabled()) {
            return;
        }
        if (bootstrap.getGitUrl() == null || bootstrap.getGitUrl().isBlank()) {
            log.warn("DocViz bootstrap: docviz.bootstrap.enabled=true pero git-url está vacío; se omite.");
            return;
        }

        log.info("========== DocViz bootstrap: clone + ingest ==========");
        log.info(
                "DocViz bootstrap: git-url={}, userId={}, runIngest={}",
                bootstrap.getGitUrl(),
                bootstrap.getUserId(),
                bootstrap.isRunIngest());

        CurrentUser.set(bootstrap.getUserId());
        try {
            GitConnectRequest req = new GitConnectRequest();
            req.setMode(GitConnectionMode.HTTPS_PUBLIC);
            req.setRepositoryUrl(bootstrap.getGitUrl());

            gitRepositoryService.connect(req);

            var session = sessionRegistry.current();
            log.info(
                    "DocViz bootstrap: repositorio listo — root={}, revision={}, label={}",
                    session.getRepositoryRoot(),
                    session.getRevisionSpec(),
                    session.getRootFolderLabel());

            if (!bootstrap.isRunIngest()) {
                log.info("DocViz bootstrap: run-ingest=false, fin.");
                return;
            }
            if (!vectorProperties.isEnabled()) {
                log.warn("DocViz bootstrap: docviz.vector.enabled=false, se omite ingesta");
                return;
            }

            log.info("DocViz bootstrap: iniciando ingesta vectorial (embed + almacén)...");
            var response = vectorIngestService.ingestAll();
            log.info(
                    "DocViz bootstrap: ingesta terminada — files={}, chunks={}, namespace={}",
                    response.getFilesProcessed(),
                    response.getChunksIndexed(),
                    response.getNamespace());
        } catch (Exception e) {
            log.error(
                    "DocViz bootstrap falló: {} — {}",
                    e.getClass().getSimpleName(),
                    e.getMessage() != null ? e.getMessage() : "",
                    e);
        } finally {
            CurrentUser.clear();
            log.info("========== DocViz bootstrap: fin ==========");
        }
    }
}
