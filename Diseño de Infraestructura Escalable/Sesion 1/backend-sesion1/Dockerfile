# syntax=docker/dockerfile:1
# DocViz API — Java 21 + Spring Boot
# Perfil Maven: "local" = Ollama (por defecto) | "!local,develop" = Gemini (p. ej. Railway: --build-arg MAVEN_PROFILES='!local,develop')
FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /src

ARG MAVEN_PROFILES=local

COPY pom.xml .
RUN mvn -q -B "-P${MAVEN_PROFILES}" dependency:resolve -DskipTests

COPY src ./src
RUN mvn -q -B -DskipTests "-P${MAVEN_PROFILES}" package

# Debian (glibc): gRPC/Firestore + netty-tcnative suelen fallar con SIGSEGV en Alpine (musl).
FROM eclipse-temurin:21-jre-jammy
LABEL org.opencontainers.image.title="DocViz Backend" \
      org.opencontainers.image.description="Document Context Visualizer API"

# git + wget: el backend usa ProcessBuilder → binario `git` (clone, ls-tree, show, checkout…), no JGit embebido.
RUN apt-get update && apt-get install -y --no-install-recommends git wget ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && git --version \
    && test -x /usr/bin/git

WORKDIR /app
COPY --from=build /src/target/backend-sesion1-*.jar /app/app.jar

EXPOSE 8080

# El filtro DocViz exige X-DocViz-User en todas las rutas
HEALTHCHECK --interval=30s --timeout=5s --start-period=90s --retries=3 \
  CMD wget -qO- --header="X-DocViz-User: healthcheck" http://127.0.0.1:8080/docviz/tags >/dev/null || exit 1

ENTRYPOINT ["java", "-jar", "/app/app.jar"]

# Scripts pgvector en el host (Postgres accesible; pip install -r scripts/requirements-smoke.txt):
#   python scripts/pgvector_smoke_test.py
#   python scripts/pgvector_clear.py --list
#   python scripts/pgvector_clear.py --namespace TU_NAMESPACE
#   python scripts/pgvector_clear.py --all --yes
