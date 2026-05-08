package com.bsg.docviz.config;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import org.springframework.core.env.Environment;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;

import javax.sql.DataSource;
import java.sql.Connection;
import java.sql.Statement;

/**
 * Al arrancar, comprueba conectividad a PostgreSQL (pgvector) y a Ollama (embeddings) y lo deja explícito en logs.
 */
@Component
@Profile("!test")
@Order(Ordered.HIGHEST_PRECEDENCE)
public class DocvizInfrastructureStartupLogger implements ApplicationRunner {

    private static final Logger log = LoggerFactory.getLogger(DocvizInfrastructureStartupLogger.class);

    private final Environment env;
    private final ObjectProvider<DataSource> dataSource;

    public DocvizInfrastructureStartupLogger(Environment env, ObjectProvider<DataSource> dataSource) {
        this.env = env;
        this.dataSource = dataSource;
    }

    @Override
    public void run(ApplicationArguments args) {
        log.info("========== DocViz: comprobación de infraestructura (PostgreSQL + Ollama) ==========");
        String store = env.getProperty("docviz.vector.store", "pgvector");
        if ("pgvector".equalsIgnoreCase(store)) {
            DataSource ds = dataSource.getIfAvailable();
            if (ds == null) {
                log.warn("DocViz infra: store=pgvector pero no hay DataSource; omite check JDBC");
            } else {
                String url = env.getProperty("spring.datasource.url", "");
                String user = env.getProperty("spring.datasource.username", "");
                try (Connection c = ds.getConnection();
                        Statement st = c.createStatement()) {
                    st.execute("SELECT 1");
                    log.info("DocViz infra: PostgreSQL conectado (url={}, user={})", url, user);
                } catch (Exception e) {
                    log.error(
                            "DocViz infra: PostgreSQL no accesible (url={}, user={}) — {}",
                            url,
                            user,
                            e.getMessage() != null ? e.getMessage() : e.getClass().getSimpleName());
                }
            }
        } else {
            log.info("DocViz infra: almacén vectorial={}, no se valida JDBC para pgvector", store);
        }

        String provider = env.getProperty("docviz.vector.embeddings-provider", "spring-ollama");
        if ("spring-ollama".equalsIgnoreCase(provider)) {
            String base = firstNonBlank(
                    env.getProperty("spring.ai.ollama.base-url"),
                    System.getenv("OLLAMA_BASE_URL"),
                    "http://127.0.0.1:11434");
            base = base.replaceAll("/+$", "");
            try {
                RestClient.builder()
                        .baseUrl(base)
                        .build()
                        .get()
                        .uri("/api/tags")
                        .retrieve()
                        .toBodilessEntity();
                log.info("DocViz infra: Ollama responde en {} (GET /api/tags)", base);
            } catch (Exception e) {
                log.warn(
                        "DocViz infra: Ollama no responde en {} — {} (¿arrancado? ¿OLLAMA_BASE_URL?)",
                        base,
                        e.getMessage() != null ? e.getMessage() : e.getClass().getSimpleName());
            }
        } else {
            log.info("DocViz infra: embeddings-provider={}, no se valida Ollama HTTP", provider);
        }
        if ("spring-ai".equalsIgnoreCase(provider)) {
            String openAiKey =
                    firstNonBlank(
                            env.getProperty("spring.ai.openai.embedding.api-key"),
                            System.getenv("OPENAI_API_KEY"));
            if (openAiKey == null || openAiKey.isBlank()) {
                log.error(
                        "DocViz infra: falta OPENAI_API_KEY (o spring.ai.openai.embedding.api-key). "
                                + "La ingesta devolverá 0 fragmentos y los errores irán a lastIngestSkipped.");
            } else {
                log.info(
                        "DocViz infra: clave API de embeddings OpenAI definida (longitud={})",
                        openAiKey.length());
            }
        }
        log.info("========== DocViz: fin comprobación infraestructura ==========");
    }

    private static String firstNonBlank(String... values) {
        if (values == null) {
            return "";
        }
        for (String v : values) {
            if (v != null && !v.isBlank()) {
                return v.trim();
            }
        }
        return "";
    }
}
