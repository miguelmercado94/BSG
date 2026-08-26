# Etapa 1: Construcción
FROM maven:3.9-eclipse-temurin-21 AS builder
WORKDIR /app
COPY pom.xml .
# Descargar dependencias para cachear
RUN mvn dependency:go-offline -B
COPY src ./src
# Compilar el proyecto y saltar tests para agilizar el build de la imagen
RUN mvn clean package -Plocal -DskipTests

# Etapa 2: Ejecución
FROM eclipse-temurin:21-jre-jammy
WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends curl && rm -rf /var/lib/apt/lists/*

# Copiar el jar generado desde la etapa builder
COPY --from=builder /app/target/*.jar app.jar

# Variable de entorno por defecto para el perfil
ENV SPRING_PROFILES_ACTIVE=local

# Exponer el puerto de la aplicación (asumiendo que usa el 8080)
EXPOSE 8080

# El entrypoint usa la variable de entorno SPRING_PROFILES_ACTIVE
# Para correr con perfil 'nube': docker run -e SPRING_PROFILES_ACTIVE=nube <imagen>
ENTRYPOINT ["java", "-jar", "app.jar"]