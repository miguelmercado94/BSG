package com.bsg.docviz.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "docviz.vector")
public class VectorProperties {

    /**
     * Almacén de vectores: {@code pgvector} (PostgreSQL + extensión pgvector) o {@code pinecone} (API HTTP legada).
     */
    private String store = "pgvector";

    /**
     * Origen de los vectores de embedding: {@code spring-ollama} (Spring AI + Ollama, recomendado con pgvector) o
     * {@code pinecone-inference} (API HTTP de inferencia Pinecone; requiere PINECONE_API_KEY).
     */
    private String embeddingsProvider = "spring-ollama";

    /**
     * Dimensión del vector de embedding (debe coincidir con el modelo; p. ej. nomic-embed-text → 768).
     * Solo aplica a {@code store=pgvector} (DDL de la columna {@code vector(dim)}).
     */
    private int embeddingDimensions = 768;

    private boolean enabled = true;
    private String pineconeApiKey = "";
    private String pineconeIndexName = "docviz-embed";
    private String pineconeIndexHost = "";
    /**
     * Host de la API de inferencia (embeddings). No es el host del índice de datos.
     * @see <a href="https://docs.pinecone.io/reference/api/2025-10/inference/generate-embeddings">Generate embeddings</a>
     */
    private String pineconeInferenceHost = "api.pinecone.io";
    private String pineconeEmbedModel = "llama-text-embed-v2";
    private long embedBatchDelayMs = 2500;
    /**
     * Cuántos chunks de texto van en una sola petición HTTP a Pinecone {@code /embed} (menos llamadas = más rápido).
     * Ajusta si la API devuelve error por payload o rate limit.
     */
    private int embedChunkBatchSize = 32;
    /**
     * Si true, el prefetch de ingesta usa un pool fijo de hilos de plataforma.
     * Si false, usa un {@link java.util.concurrent.Executors#newCachedThreadPool(ThreadFactory)} con hilos daemon
     * (compatible con Java 17+; los hilos virtuales solo en JRE 21 no se usan aquí para evitar errores de runtime).
     */
    private boolean prefetchUsePlatformThreads = false;
    private int chunkSize = 800;
    private int chunkOverlap = 120;
    private int ragTopK = 6;
    /**
     * Tope de caracteres del bloque de contexto RAG (chunks + menciones) enviado al LLM. Si se supera, se trunca el
     * final con aviso en logs — evita HTTP 400 de Ollama: "the input length exceeds the context length".
     */
    private int ragMaxContextChars = 12000;
    /**
     * Si es true, la ingesta solo indexa {@link #classpathSampleResource} desde el classpath (sin leer el repo Git).
     * Útil para depurar Pinecone/embeddings. Desactivar para indexar todo el repositorio.
     */
    private boolean ingestClasspathSampleOnly = false;
    /** Ruta bajo {@code src/main/resources} (p. ej. un .py de prueba para ingesta mínima). */
    private String classpathSampleResource = "test_gemini_key.py";

    public String getStore() {
        return store;
    }

    public void setStore(String store) {
        this.store = store != null ? store.trim().toLowerCase() : "pgvector";
    }

    public String getEmbeddingsProvider() {
        return embeddingsProvider;
    }

    public void setEmbeddingsProvider(String embeddingsProvider) {
        this.embeddingsProvider =
                embeddingsProvider != null ? embeddingsProvider.trim().toLowerCase() : "spring-ollama";
    }

    public int getEmbeddingDimensions() {
        return embeddingDimensions;
    }

    public void setEmbeddingDimensions(int embeddingDimensions) {
        int d = embeddingDimensions;
        if (d < 64) {
            d = 64;
        } else if (d > 4096) {
            d = 4096;
        }
        this.embeddingDimensions = d;
    }

    public boolean isEnabled() {
        return enabled;
    }

    public void setEnabled(boolean enabled) {
        this.enabled = enabled;
    }

    public String getPineconeApiKey() {
        return pineconeApiKey;
    }

    public void setPineconeApiKey(String pineconeApiKey) {
        this.pineconeApiKey = pineconeApiKey;
    }

    public String getPineconeIndexName() {
        return pineconeIndexName;
    }

    public void setPineconeIndexName(String pineconeIndexName) {
        this.pineconeIndexName = pineconeIndexName;
    }

    public String getPineconeIndexHost() {
        return pineconeIndexHost;
    }

    public void setPineconeIndexHost(String pineconeIndexHost) {
        this.pineconeIndexHost = pineconeIndexHost;
    }

    public String getPineconeInferenceHost() {
        return pineconeInferenceHost;
    }

    public void setPineconeInferenceHost(String pineconeInferenceHost) {
        this.pineconeInferenceHost = pineconeInferenceHost;
    }

    public String getPineconeEmbedModel() {
        return pineconeEmbedModel;
    }

    public void setPineconeEmbedModel(String pineconeEmbedModel) {
        this.pineconeEmbedModel = pineconeEmbedModel;
    }

    public long getEmbedBatchDelayMs() {
        return embedBatchDelayMs;
    }

    public void setEmbedBatchDelayMs(long embedBatchDelayMs) {
        this.embedBatchDelayMs = embedBatchDelayMs;
    }

    public int getEmbedChunkBatchSize() {
        return embedChunkBatchSize;
    }

    public void setEmbedChunkBatchSize(int embedChunkBatchSize) {
        int v = embedChunkBatchSize;
        if (v < 1) {
            v = 1;
        } else if (v > 128) {
            v = 128;
        }
        this.embedChunkBatchSize = v;
    }

    public boolean isPrefetchUsePlatformThreads() {
        return prefetchUsePlatformThreads;
    }

    public void setPrefetchUsePlatformThreads(boolean prefetchUsePlatformThreads) {
        this.prefetchUsePlatformThreads = prefetchUsePlatformThreads;
    }

    public int getChunkSize() {
        return chunkSize;
    }

    public void setChunkSize(int chunkSize) {
        this.chunkSize = chunkSize;
    }

    public int getChunkOverlap() {
        return chunkOverlap;
    }

    public void setChunkOverlap(int chunkOverlap) {
        this.chunkOverlap = chunkOverlap;
    }

    public int getRagTopK() {
        return ragTopK;
    }

    public void setRagTopK(int ragTopK) {
        this.ragTopK = ragTopK;
    }

    public int getRagMaxContextChars() {
        return ragMaxContextChars;
    }

    public void setRagMaxContextChars(int ragMaxContextChars) {
        int v = ragMaxContextChars;
        if (v < 2000) {
            v = 2000;
        } else if (v > 500000) {
            v = 500000;
        }
        this.ragMaxContextChars = v;
    }

    public boolean isIngestClasspathSampleOnly() {
        return ingestClasspathSampleOnly;
    }

    public void setIngestClasspathSampleOnly(boolean ingestClasspathSampleOnly) {
        this.ingestClasspathSampleOnly = ingestClasspathSampleOnly;
    }

    public String getClasspathSampleResource() {
        return classpathSampleResource;
    }

    public void setClasspathSampleResource(String classpathSampleResource) {
        this.classpathSampleResource = classpathSampleResource;
    }
}
