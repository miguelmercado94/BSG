# BSG back-security-sesion1 — imagen runtime (JRE 21 Alpine).
FROM gradle:8.14-jdk21 AS builder
WORKDIR /workspace

COPY settings.gradle build.gradle ./
COPY src src

RUN gradle bootJar -x test -x check --no-daemon --warning-mode none

FROM eclipse-temurin:21-jre-alpine
WORKDIR /app

RUN addgroup -S spring -g 1000 && adduser -S spring -u 1000 -G spring \
    && apk add --no-cache curl \
    && rm -rf /var/cache/apk/*

COPY --from=builder /workspace/build/libs/*.jar /app/app.jar

USER spring:spring

EXPOSE 8081

ENTRYPOINT ["sh", "-c", "exec java ${JAVA_OPTS:-} -jar /app/app.jar"]
