# Build
FROM maven:3.9-eclipse-temurin-17 AS build
WORKDIR /src
COPY pom.xml .
COPY src ./src
RUN mvn -q -DskipTests package

# Run (git requerido para clone / lectura de repos)
FROM eclipse-temurin:17-jre-alpine
RUN apk add --no-cache git
WORKDIR /app
COPY --from=build /src/target/backend-sesion1-*.jar /app/app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "/app/app.jar"]
