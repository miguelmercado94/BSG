# backend-sesion1 (DocViz API)

Backend **Spring Boot** del proyecto DocViz — Sesión 1: Git/workspaces, chat RAG, área de trabajo S3, vector store (pgvector / Pinecone según configuración), integración con **Ollama** o **Gemini** según `SPRING_PROFILES_ACTIVE` en runtime (mismo JAR / imagen Docker).

---

## Requisitos

- **JDK 21**
- **Maven** (el repo incluye **`mvnw`** / **`mvnw.cmd`**)
- Servicios según modo de ejecución: **PostgreSQL**, **Ollama** (perfil local), **LocalStack** (S3 soporte/workarea), opcionalmente otros según `.env`

---

## Configuración

1. Copia **`backend-sesion1/.env.example`** → **`.env`** y ajusta URLs y credenciales.
2. Perfiles Maven típicos: **`local`** (desarrollo con Ollama), **`develop`** (u otros definidos en `pom.xml`).

Variables importantes (ver `.env.example`): `DATABASE_*`, `DOCVIZ_*`, Redis, S3 soporte, etc.

---

## Ejecutar en local (Windows)

Desde **`backend-sesion1`**:

| Script | Descripción |
|--------|-------------|
| **`mvn-jdk21.ps1`** | Ejecuta **`mvnw.cmd`** con `JAVA_HOME` apuntando a JDK 21. Ejemplo: `.\mvn-jdk21.ps1 spring-boot:run` |
| **`run-backend-local.ps1`** | Igual que arrancar Spring Boot con JDK 21 y valores por defecto útiles (`OLLAMA_BASE_URL`, endpoint S3 LocalStack, etc.) |

Ejemplo manual sin script:

```powershell
$env:JAVA_HOME = "C:\Program Files\Java\jdk-21"
$env:Path = "$env:JAVA_HOME\bin;$env:Path"
.\mvnw.cmd spring-boot:run
```

Linux/macOS:

```bash
export JAVA_HOME=/path/to/jdk-21
./mvnw spring-boot:run
```

---

## Docker

La imagen se construye con **`backend-sesion1/Dockerfile`**. En **`Sesion 1/docker-compose.yml`**, servicio típico **`backend`** (perfil **`containerized`**).

Publicación en Docker Hub: ver **`Sesion 1/DOCKERHUB.md`** (incluye también **back-security** como `docviz-sesion1-back-security`).

---

## Tests

```bash
./mvnw test
```

En Windows: `.\mvnw.cmd test` (o `.\mvn-jdk21.ps1 test`).

---

## Documentación relacionada

- **`Sesion 1/docker-compose.yml`** — Orquestación de infra y apps.
- **`Sesion 1/DOCKERHUB.md`** — Imágenes backend/frontend.
- **`CI-RAILWAY.md`** (si existe en el repo) — Despliegue continuo.
