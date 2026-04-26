# syntax=docker/dockerfile:1
# DocViz API — Java 21 + Spring Boot. Build neutral: sin perfiles Maven ni build-args de entorno.
# Ollama vs Gemini: SPRING_PROFILES_ACTIVE=local|develop y variables en docker-compose / Railway / .env.
FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /src

COPY pom.xml .
RUN mvn -q -B dependency:resolve -DskipTests

COPY src ./src
RUN mvn -q -B -DskipTests package

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

# Empaquetar las credenciales de Firebase dentro del contenedor
COPY sesion-bsg-firebase-adminsdk-fbsvc-25ee0429da.json /app/

EXPOSE 8080

# El filtro DocViz exige X-DocViz-User en todas las rutas
HEALTHCHECK --interval=30s --timeout=5s --start-period=90s --retries=3 \
  CMD wget -qO- --header="X-DocViz-User: healthcheck" http://127.0.0.1:8080/docviz/tags >/dev/null || exit 1

ENTRYPOINT ["java", "-jar", "/app/app.jar"]
