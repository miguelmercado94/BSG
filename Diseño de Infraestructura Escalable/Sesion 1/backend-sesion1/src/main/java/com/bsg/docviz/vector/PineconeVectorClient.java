package com.bsg.docviz.vector;

import com.bsg.docviz.config.VectorProperties;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.stereotype.Component;

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

@Component
public class PineconeVectorClient {

    private static final String API_VERSION = "2025-10";
    private final VectorProperties props;
    private final ObjectMapper json = new ObjectMapper();
    private final HttpClient http = HttpClient.newBuilder().connectTimeout(Duration.ofSeconds(15)).build();

    public PineconeVectorClient(VectorProperties props) {
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

    public float[] embedQuery(String text) {
        requireKey();
        List<float[]> batch = embedTexts(List.of(text), "query");
        return batch.get(0);
    }

    /**
     * Embeddings para fragmentos de documento (ingesta).
     */
    public List<float[]> embedTexts(List<String> texts) {
        return embedTexts(texts, "passage");
    }

    private List<float[]> embedTexts(List<String> texts, String inputType) {
        requireKey();
        if (texts == null || texts.isEmpty()) {
            return List.of();
        }
        String inferenceHost = normalizeHost(props.getPineconeInferenceHost());
        if (inferenceHost.isBlank()) {
            inferenceHost = "api.pinecone.io";
        }
        try {
            var embedBody = json.createObjectNode();
            embedBody.put("model", props.getPineconeEmbedModel());
            var parameters = json.createObjectNode();
            parameters.put("input_type", inputType);
            parameters.put("truncate", "END");
            embedBody.set("parameters", parameters);
            var inputs = json.createArrayNode();
            for (String t : texts) {
                var one = json.createObjectNode();
                one.put("text", t);
                inputs.add(one);
            }
            embedBody.set("inputs", inputs);
            String body = json.writeValueAsString(embedBody);
            String url = "https://" + inferenceHost + "/embed";
            HttpRequest req = HttpRequest.newBuilder()
                    .uri(URI.create(url))
                    .timeout(Duration.ofMinutes(2))
                    .header("Api-Key", props.getPineconeApiKey())
                    .header("Content-Type", "application/json")
                    .header("X-Pinecone-Api-Version", API_VERSION)
                    .POST(HttpRequest.BodyPublishers.ofString(body, StandardCharsets.UTF_8))
                    .build();
            HttpResponse<String> res = http.send(req, HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));
            if (res.statusCode() / 100 != 2) {
                throw new IllegalStateException("Pinecone embed HTTP " + res.statusCode() + ": " + res.body());
            }
            return parseEmbedResponse(res.body(), texts.size());
        } catch (IOException | InterruptedException e) {
            if (e instanceof InterruptedException) {
                Thread.currentThread().interrupt();
            }
            throw new IllegalStateException("Pinecone embed failed: " + e.getMessage(), e);
        }
    }

    private List<float[]> parseEmbedResponse(String body, int expected) throws IOException {
        JsonNode root = json.readTree(body);
        List<float[]> out = new ArrayList<>();
        JsonNode data = root.path("data");
        if (data.isArray()) {
            for (JsonNode item : data) {
                JsonNode vals = item.path("values");
                if (vals.isArray()) {
                    float[] v = new float[vals.size()];
                    for (int i = 0; i < vals.size(); i++) {
                        v[i] = (float) vals.get(i).asDouble();
                    }
                    out.add(v);
                }
            }
        }
        if (out.size() != expected && root.path("embeddings").isArray()) {
            out.clear();
            for (JsonNode emb : root.withArray("embeddings")) {
                float[] v = new float[emb.size()];
                for (int i = 0; i < emb.size(); i++) {
                    v[i] = (float) emb.get(i).asDouble();
                }
                out.add(v);
            }
        }
        if (out.isEmpty()) {
            throw new IllegalStateException("Could not parse embed response: " + body);
        }
        return out;
    }

    public List<PineconeMatch> queryTopK(
            String indexHost,
            String namespace,
            float[] vector,
            int topK,
            String userLabel
    ) {
        requireKey();
        String host = normalizeHost(indexHost);
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

    private List<PineconeMatch> parseQueryMatches(String body, String userLabel) throws IOException {
        List<PineconeMatch> matches = new ArrayList<>();
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
                matches.add(new PineconeMatch(source, chunk, score));
            }
        }
        return matches;
    }

    public void upsertBatch(String indexHost, String namespace, List<VectorRecord> records) {
        requireKey();
        if (records == null || records.isEmpty()) {
            return;
        }
        String host = normalizeHost(indexHost);
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

    public record VectorRecord(String id, float[] vector, String source, int chunkIndex, String userLabel) {
    }
}
