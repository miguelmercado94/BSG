package com.bsg.docviz.vector;

import com.bsg.docviz.config.VectorProperties;
import com.bsg.docviz.util.TextChunker;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.ai.embedding.Embedding;
import org.springframework.ai.embedding.EmbeddingModel;
import org.springframework.ai.embedding.EmbeddingResponse;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import org.testcontainers.utility.DockerImageName;

import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.mockito.ArgumentMatchers.anyList;
import static org.mockito.Mockito.when;

/**
 * Replica el flujo del script Python (chunk → embed → INSERT pgvector): mismo {@link TextChunker},
 * {@link EmbeddingClient} y {@link VectorStore} que en producción. El modelo de embedding está mockeado
 * (vectores de dimensión fija); Ollama real se valida al arrancar el backend (sin perfil {@code test}).
 * <p>
 * Requiere Docker para levantar {@code pgvector/pgvector:pg16}. Si Docker no está disponible, el test se
 * omite (no falla) gracias a {@code disabledWithoutDocker}.
 */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.NONE)
@ActiveProfiles("test")
@Testcontainers(disabledWithoutDocker = true)
class PgVectorIngestPipelineTest {

    private static final String NAMESPACE = "it_pipeline_test";

    @Container
    static final PostgreSQLContainer<?> POSTGRES =
            new PostgreSQLContainer<>(DockerImageName.parse("pgvector/pgvector:pg16"));

    @DynamicPropertySource
    static void registerDatasource(DynamicPropertyRegistry r) {
        r.add("spring.datasource.url", POSTGRES::getJdbcUrl);
        r.add("spring.datasource.username", POSTGRES::getUsername);
        r.add("spring.datasource.password", POSTGRES::getPassword);
        r.add("docviz.vector.store", () -> "pgvector");
        r.add("docviz.vector.embedding-dimensions", () -> "768");
        r.add("docviz.vector.embed-batch-delay-ms", () -> "0");
    }

    @MockBean
    private EmbeddingModel embeddingModel;

    @Autowired
    private EmbeddingClient embeddingClient;

    @Autowired
    private VectorStore vectorStore;

    @Autowired
    private VectorProperties vectorProperties;

    @BeforeEach
    void mockEmbeddingsMatchConfiguredDim() {
        int dim = vectorProperties.getEmbeddingDimensions();
        when(embeddingModel.embedForResponse(anyList())).thenAnswer(invocation -> {
            List<String> texts = invocation.getArgument(0);
            List<Embedding> embeddings = new ArrayList<>();
            for (int i = 0; i < texts.size(); i++) {
                float[] v = new float[dim];
                Arrays.fill(v, (i + 1) * 0.001f);
                embeddings.add(new Embedding(v, i));
            }
            return new EmbeddingResponse(embeddings);
        });
    }

    @AfterEach
    void cleanupNamespace() {
        vectorStore.deleteAllInNamespace(NAMESPACE);
    }

    @Test
    void loadsTestResourceChunksEmbedsAndUpsertsToPostgres() throws Exception {
        String text;
        try (InputStream in = getClass().getResourceAsStream("/ingest-pipeline-sample.txt")) {
            assertNotNull(in, "ingest-pipeline-sample.txt debe existir en src/test/resources");
            text = new String(in.readAllBytes(), StandardCharsets.UTF_8);
        }

        List<String> parts =
                TextChunker.chunk(text, vectorProperties.getChunkSize(), vectorProperties.getChunkOverlap());
        assertFalse(parts.isEmpty(), "el sample debe producir al menos un chunk");

        List<float[]> vectors = embeddingClient.embedTexts(parts);
        assertEquals(parts.size(), vectors.size());

        List<VectorRecord> batch = new ArrayList<>();
        for (int i = 0; i < parts.size(); i++) {
            batch.add(
                    new VectorRecord(
                            UUID.randomUUID().toString(),
                            vectors.get(i),
                            "classpath:ingest-pipeline-sample.txt",
                            i,
                            "test-user"));
        }
        vectorStore.upsertBatch(NAMESPACE, batch);

        float[] query = embeddingClient.embedQuery("RAG búsqueda similitud");
        List<VectorMatch> hits = vectorStore.queryTopK(NAMESPACE, query, Math.min(5, parts.size()), "test-user");
        assertFalse(hits.isEmpty(), "debe haber coincidencias en el namespace de prueba");
    }
}
