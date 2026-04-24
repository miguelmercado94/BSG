package com.bsg.docviz.config;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.env.EnvironmentPostProcessor;
import org.springframework.core.env.ConfigurableEnvironment;
import org.springframework.core.env.MapPropertySource;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Carga {@code .env} del directorio de trabajo (p. ej. {@code backend-sesion1/.env}) para que
 * {@code mvn spring-boot:run} vea {@code PINECONE_API_KEY} igual que Docker Compose con {@code env_file}.
 * No sustituye variables ya definidas en el SO ({@code System.getenv}).
 */
public class DotenvEnvironmentPostProcessor implements EnvironmentPostProcessor {

    private static final Pattern LINE = Pattern.compile("^([A-Za-z_][A-Za-z0-9_]*)=(.*)$");

    @Override
    public void postProcessEnvironment(ConfigurableEnvironment env, SpringApplication app) {
        Path envPath = resolveEnvFile();
        if (envPath == null || !Files.isRegularFile(envPath)) {
            return;
        }
        Map<String, Object> map = new HashMap<>();
        try {
            List<String> lines = Files.readAllLines(envPath);
            for (String raw : lines) {
                String line = raw.trim();
                if (line.isEmpty() || line.startsWith("#")) {
                    continue;
                }
                Matcher m = LINE.matcher(line);
                if (!m.matches()) {
                    continue;
                }
                String key = m.group(1);
                String value = m.group(2).trim();
                if (value.startsWith("\"") && value.endsWith("\"") && value.length() >= 2) {
                    value = value.substring(1, value.length() - 1);
                } else if (value.startsWith("'") && value.endsWith("'") && value.length() >= 2) {
                    value = value.substring(1, value.length() - 1);
                }
                String existing = System.getenv(key);
                if (existing != null && !existing.isEmpty()) {
                    continue;
                }
                map.put(key, value);
            }
        } catch (IOException e) {
            return;
        }
        if (map.isEmpty()) {
            return;
        }
        MapPropertySource ps = new MapPropertySource("docvizDotenv", map);
        if (env.getPropertySources().get("systemEnvironment") != null) {
            env.getPropertySources().addAfter("systemEnvironment", ps);
        } else {
            env.getPropertySources().addFirst(ps);
        }
    }

    private static Path resolveEnvFile() {
        Path a = Paths.get(".env");
        if (Files.isRegularFile(a)) {
            return a.toAbsolutePath();
        }
        Path b = Paths.get("backend-sesion1", ".env");
        if (Files.isRegularFile(b)) {
            return b.toAbsolutePath();
        }
        return null;
    }
}
