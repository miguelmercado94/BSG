# syntax=docker/dockerfile:1
FROM eclipse-temurin:21-jre-jammy
LABEL org.opencontainers.image.title="DocViz Backend" \
      org.opencontainers.image.description="Document Context Visualizer API"

# git + wget: el backend usa ProcessBuilder → binario `git` (clone, ls-tree, show, checkout…), no JGit embebido.
RUN apt-get update && apt-get install -y --no-install-recommends git wget ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && git --version \
    && test -x /usr/bin/git

WORKDIR /app
COPY target/backend-sesion1-*.jar /app/app.jar

# Empaquetar las credenciales de Firebase dentro del contenedor
COPY sesion-bsg-firebase-adminsdk-fbsvc-25ee0429da.json /app/

EXPOSE 8080

# El filtro DocViz exige X-DocViz-User en todas las rutas
HEALTHCHECK --interval=35s --timeout=12s --start-period=120s --retries=5 \
  CMD wget -qO- --header="X-DocViz-User: healthcheck" http://127.0.0.1:8080/docviz/tags >/dev/null || exit 1

ENTRYPOINT ["java", "-jar", "/app/app.jar"]
