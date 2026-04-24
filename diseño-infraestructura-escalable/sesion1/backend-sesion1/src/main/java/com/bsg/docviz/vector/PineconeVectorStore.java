package com.bsg.docviz.vector;

import com.bsg.docviz.config.VectorProperties;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.io.IOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.ArrayList;
import java.util.List;
import java.util.Objects;

/**
 * Almacén vectorial vía API HTTP Pinecone (índice + upsert/query/delete).
 */
public class PineconeVectorStore implements VectorStore {

    private static final String API_VERSION = "2025-10";
    private final VectorProperties props;
    private final ObjectMapper json = new ObjectMapper();
    private final HttpClient http = HttpClient.newBuilder().connectTimeout(Duration.ofSeconds(15)).build();

    public PineconeVectorStore(VectorProperties props) {
        this.props = props;
    }

    public String getIndexHost() {
        return normalizeHost(props.getPineconeIndexHost());
    }

    private String normalizeHost(String host) {
        if (host == null || host.isBlank()) {
            return "";
        }
        String h = host.trim();
        if (h.startsWith("https://")) {
            return h.substring("https://".length());
        }
        if (h.startsWith("http://")) {
            return h.substring("http://".length());
        }
        return h;
    }

    private void requireKey() {
        if (props.getPineconeApiKey() == null || props.getPineconeApiKey().isBlank()) {
            throw new IllegalStateException(
                    "Falta la API key de Pinecone: define PINECONE_API_KEY o docviz.vector.pinecone-api-key.");
        }
    }

    @Override
    public List<VectorMatch> queryTopK(String namespace, float[] vector, int topK, String userLabel) {
        requireKey();
        String host = normalizeHost(props.getPineconeIndexHost());
        try {
            var query = json.createObjectNode();
            query.put("namespace", namespace);
            query.put("topK", topK);
            query.set("vector", json.valueToTree(vector));
            query.put("includeMetadata", true);
            String qjson = json.writeValueAsString(query);
            String url = "https://" + host + "/query";
            HttpRequest req = HttpRequest.newBuilder()
                    .uri(URI.create(url))
                    .timeout(Duration.ofSeconds(60))
                    .header("Api-Key", props.getPineconeApiKey())
                    .header("Content-Type", "application/json")
                    .header("X-Pinecone-Api-Version", API_VERSION)
                    .POST(HttpRequest.BodyPublishers.ofString(qjson, StandardCharsets.UTF_8))
                    .build();
            HttpResponse<String> res = http.send(req, HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));
            if (res.statusCode() / 100 != 2) {
                throw new IllegalStateException("Pinecone query HTTP " + res.statusCode() + ": " + res.body());
            }
            return parseQueryMatches(res.body(), userLabel);
        } catch (IOException | InterruptedException e) {
            if (e instanceof InterruptedException) {
                Thread.currentThread().interrupt();
            }
            throw new IllegalStateException("Pinecone query failed: " + e.getMessage(), e);
        }
    }

    private List<VectorMatch> parseQueryMatches(String body, String userLabel) throws IOException {
        List<VectorMatch> matches = new ArrayList<>();
        JsonNode root = json.readTree(body);
        JsonNode matchesNode = root.path("matches");
        if (!matchesNode.isArray()) {
            return matches;
        }
        for (JsonNode m : matchesNode) {
            double score = m.path("score").asDouble();
            JsonNode meta = m.path("metadata");
            String source = meta.path("source").asText("");
            int chunk = meta.path("chunkIndex").asInt(0);
            String ul = meta.path("userLabel").asText("");
            if (userLabel != null && !userLabel.isBlank() && !ul.isBlank() && !Objects.equals(ul, userLabel)) {
                continue;
            }
            if (!source.isBlank()) {
                matches.add(new VectorMatch(source, chunk, score));
            }
        }
        return matches;
    }

    @Override
    public void deleteAllInNamespace(String namespace) {
        deleteAllVectorsInNamespace(getIndexHost(), namespace);
    }

    @Override
    public void deleteBySource(String namespace, String source) {
        requireKey();
        if (namespace == null || source == null || source.isBlank()) {
            throw new IllegalArgumentException("namespace and source required");
        }
        String host = normalizeHost(props.getPineconeIndexHost());
        try {
            var body = json.createObjectNode();
            body.put("namespace", namespace);
            var filter = json.createObjectNode();
            var eq = json.createObjectNode();
            eq.put("$eq", source);
            filter.set("source", eq);
            body.set("filter", filter);
            String jsonBody = json.writeValueAsString(body);
            String url = "https://" + host + "/vectors/delete";
            HttpRequest req = HttpRequest.newBuilder()
                    .uri(URI.create(url))
                    .timeout(Duration.ofMinutes(2))
                    .header("Api-Key", props.getPineconeApiKey())
                    .header("Content-Type", "application/json")
                    .header("X-Pinecone-Api-Version", API_VERSION)
                    .POST(HttpRequest.BodyPublishers.ofString(jsonBody, StandardCharsets.UTF_8))
                    .build();
            HttpResponse<String> res = http.send(req, HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));
            if (res.statusCode() / 100 != 2) {
                throw new IllegalStateException("Pinecone delete by source HTTP " + res.statusCode() + ": " + res.body());
            }
        } catch (IOException | InterruptedException e) {
            if (e instanceof InterruptedException) {
                Thread.currentThread().interrupt();
            }
            throw new IllegalStateException("Pinecone delete by source failed: " + e.getMessage(), e);
        }
    }

    /**
     * Borra todos los vectores de un namespace en el índice.
     */
    public void deleteAllVectorsInNamespace(String indexHost, String namespace) {
        requireKey();
        if (namespace == null) {
            throw new IllegalArgumentException("namespace required");
        }
        String host = normalizeHost(indexHost);
        try {
            var body = json.createObjectNode();
            body.put("deleteAll", true);
            body.put("namespace", namespace);
            String jsonBody = json.writeValueAsString(body);
            String url = "https://" + host + "/vectors/delete";
            HttpRequest req = HttpRequest.newBuilder()
                    .uri(URI.create(url))
                    .timeout(Duration.ofMinutes(2))
                    .header("Api-Key", props.getPineconeApiKey())
                    .header("Content-Type", "application/json")
                    .header("X-Pinecone-Api-Version", API_VERSION)
                    .POST(HttpRequest.BodyPublishers.ofString(jsonBody, StandardCharsets.UTF_8))
                    .build();
            HttpResponse<String> res = http.send(req, HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));
            if (res.statusCode() / 100 != 2) {
                throw new IllegalStateException("Pinecone delete HTTP " + res.statusCode() + ": " + res.body());
            }
        } catch (IOException | InterruptedException e) {
            if (e instanceof InterruptedException) {
                Thread.currentThread().interrupt();
            }
            throw new IllegalStateException("Pinecone delete failed: " + e.getMessage(), e);
        }
    }

    @Override
    public void upsertBatch(String namespace, List<VectorRecord> records) {
        requireKey();
        if (records == null || records.isEmpty()) {
            return;
        }
        String host = normalizeHost(props.getPineconeIndexHost());
        try {
            var vectors = json.createArrayNode();
            for (VectorRecord r : records) {
                var o = json.createObjectNode();
                o.put("id", r.id());
                o.set("values", json.valueToTree(r.vector()));
                var meta = json.createObjectNode();
                meta.put("source", r.source());
                meta.put("chunkIndex", r.chunkIndex());
                meta.put("userLabel", r.userLabel());
                o.set("metadata", meta);
                vectors.add(o);
            }
            var body = json.createObjectNode();
            body.put("namespace", namespace);
            body.set("vectors", vectors);
            String ujson = json.writeValueAsString(body);
            String url = "https://" + host + "/vectors/upsert";
            HttpRequest req = HttpRequest.newBuilder()
                    .uri(URI.create(url))
                    .timeout(Duration.ofMinutes(2))
                    .header("Api-Key", props.getPineconeApiKey())
                    .header("Content-Type", "application/json")
                    .header("X-Pinecone-Api-Version", API_VERSION)
                    .POST(HttpRequest.BodyPublishers.ofString(ujson, StandardCharsets.UTF_8))
                    .build();
            HttpResponse<String> res = http.send(req, HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));
            if (res.statusCode() / 100 != 2) {
                throw new IllegalStateException("Pinecone upsert HTTP " + res.statusCode() + ": " + res.body());
            }
        } catch (IOException | InterruptedException e) {
            if (e instanceof InterruptedException) {
                Thread.currentThread().interrupt();
            }
            throw new IllegalStateException("Pinecone upsert failed: " + e.getMessage(), e);
        }
    }
}
