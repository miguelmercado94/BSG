# Build
FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /src
COPY pom.xml .
COPY src ./src
# Perfil Maven "local" = dependencia Ollama (ajusta a -P"!local,develop" para imagen Gemini)
RUN mvn -q -DskipTests -Plocal package

# Run (git requerido para clone / lectura de repos)
FROM eclipse-temurin:21-jre-alpine
RUN apk add --no-cache git
WORKDIR /app
COPY --from=build /src/target/backend-sesion1-*.jar /app/app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "/app/app.jar"]
