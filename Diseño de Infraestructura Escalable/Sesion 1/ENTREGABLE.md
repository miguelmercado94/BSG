# 1. URL del servicio en producción

## Entregable — DocViz (Asistente RAG y despliegue)

**Frontend (aplicación pública):**  
https://docviz-sesion1-frontend-production.up.railway.app/

*(El backend API está desplegado por separado en Railway; el frontend usa `BACKEND_URL` / `SECURITY_URL` en runtime (contenedor) o `VITE_*` en build. El backend usa **Java 21+** — Spring Boot 3, hilos virtuales opcionales; **una sola imagen** con Ollama y Gemini en el classpath; el modo lo elige `SPRING_PROFILES_ACTIVE` en runtime.)*

---

## 2. Prompt para agente de IA (reconstrucción y despliegue)

Copia el bloque siguiente en tu agente de coding (Cursor, Claude Code, etc.). Sustituye los valores entre corchetes por los tuyos.

```text
Quiero que implementes y dejes listo para producción en Railway un asistente RAG sobre código y documentos de un repositorio Git, API-first, backend y frontend desacoplados.

=== RUNTIME Y BACKEND (JAVA 21+) ===
- Versión de Java: 21 como mínimo (LTS). No uses Java 17: el proyecto usa características propias de 21.
- Spring Boot 3.3.x (o compatible), Spring Web, Spring Validation, Spring AI para chat y embeddings hacia Pinecone.
- Hilos virtuales de Java 21: en application.properties incluye `spring.threads.virtual.enabled=true` (si el entorno de despliegue falla, documentar fallback a `false`).
- Extracción de texto de PDF en servidor: Apache PDFBox (u equivalente) para que los PDF dentro del repo pasen al pipeline de chunks.

=== CHAT OLLAMA / GEMINI (un solo JAR / imagen Docker) ===
- El `pom.xml` incluye en el classpath `spring-ai-starter-model-ollama` y `spring-ai-starter-model-google-genai`. No uses perfiles Maven para excluir uno u otro en la imagen Docker.
- Comando típico: `mvn package` o `./mvnw package` (sin `-P` para elegir chat).

=== PERFILES SPRING (solo runtime: compose, Railway, .env) ===
- Propiedad global: `spring.profiles.active=${SPRING_PROFILES_ACTIVE:local}`.
- `application-local.properties` (Spring `local`): `spring.ai.model.chat=ollama`, URLs y modelos Ollama.
- `application-develop.properties` (Spring `develop`): `spring.ai.model.chat=google-genai`, `GEMINI_API_KEY`, `GEMINI_MODEL`, etc.

Regla: `SPRING_PROFILES_ACTIVE=local` usa Ollama; `develop` usa Gemini. La misma imagen sirve para ambos.

=== application.properties (núcleo compartido) ===
Incluir al menos:
- `server.port=${PORT:8080}` para Railway.
- `spring.application.name=...`
- `spring.config.import=optional:file:./application-local.properties` si aplica overrides locales.
- Prefijo de negocio `docviz.*`, por ejemplo:
  - `docviz.context-masters.base-path` (directorio base de repos clonados o contexto maestro).
  - `docviz.vector.enabled`, `docviz.vector.pinecone-api-key=${PINECONE_API_KEY:}`, `docviz.vector.pinecone-index-name`, `docviz.vector.pinecone-index-host`, `docviz.vector.pinecone-inference-host`, `docviz.vector.pinecone-embed-model` (modelo de embeddings compatible con el índice), `docviz.vector.chunk-size`, `docviz.vector.chunk-overlap`, `docviz.vector.rag-top-k`, opciones de ingesta por lotes / hilos (`docviz.vector.prefetch-use-platform-threads=false` para preferir hilos virtuales en ingesta), etc.
- Documentar que el índice Pinecone debe existir y que la dimensión del embedding coincida con `pinecone-embed-model`.

Opcional local: cargar `.env` con springboot3-dotenv o equivalente para `PINECONE_API_KEY` sin commitear secretos.

=== API, SEGURIDAD LIGERA Y CORS ===
- Implementar identificación de usuario/sesión vía cabecera HTTP `X-DocViz-User` en las rutas del API (filtro servlet); el frontend debe enviarla en todas las peticiones; healthcheck Docker puede usar la misma cabecera en GET a una ruta existente (p. ej. `/tags`).
- CORS: permitir el origen del frontend en Railway (`https://*.up.railway.app`) y orígenes locales en desarrollo.

=== DOMINIO FUNCIONAL ===
- No subida directa de PDF como flujo principal: el usuario trabaja sobre un repositorio Git (clone en servidor). Indexar texto de archivos del árbol; PDFs dentro del repo extraídos a texto y chunkados como el resto.
- Endpoints REST: conexión/selección de repo, listado de etiquetas, lectura de contenido de archivo para vista previa, ingesta vectorial (idealmente con progreso por SSE o similar), chat RAG con fuentes opcionales.
- Chat RAG: embedding de la pregunta → top-k Pinecone → prompt con contexto → respuesta (Gemini en nube u Ollama en local según perfiles).

=== FRONTEND ===
- React + TypeScript + Vite. Bases del API: `VITE_API_URL` y `VITE_SECURITY_URL` en build, o `BACKEND_URL` y `SECURITY_URL` en el contenedor Nginx (script `docker-entrypoint.d` + `envsubst`). El cliente HTTP debe enviar `X-DocViz-User`.
- Pantallas: conexión al repo, workspace con árbol de archivos, visualizador de código, panel de consulta RAG con estado de índice.
- Dockerfile: build de Vite; Nginx sirve estáticos; en Railway el navegador llama a URLs públicas (CORS), no a un hostname interno `backend`.

=== DOCKER BACKEND ===
- Imagen build: `maven:...-temurin-21`, imagen runtime: `eclipse-temurin:21-jre-...`.
- Build Maven sin perfiles para chat: `mvn package`. Configuración solo por variables de entorno (`SPRING_PROFILES_ACTIVE`, `GEMINI_*`, `OLLAMA_*`, etc.) en compose o plataforma.
- Incluir `git` en la imagen runtime si el servidor clona o actualiza repos.
- HEALTHCHECK con `wget`/`curl` contra `http://127.0.0.1:${PORT}/...` y cabecera `X-DocViz-User`.

=== DESPLIEGUE RAILWAY ===
- Dos servicios, mismo repositorio: Root Directory `backend-sesion1` y `frontend-sesion1`.
- Backend: `SPRING_PROFILES_ACTIVE=develop`; `GEMINI_API_KEY`, `GEMINI_MODEL` (opcional); `PINECONE_API_KEY`; resto según `application.properties`. Sin build-args Maven en la imagen.
- Frontend: variables `BACKEND_URL` y `SECURITY_URL` en el servicio (o build-args `VITE_*` equivalentes).
- Orden: desplegar backend → copiar URLs HTTPS → configurar frontend.

=== ENTREGABLE TÉCNICO ===
- `./mvnw` (o `mvn`) y `npm run build` sin errores; Dockerfiles probados; documentación breve (p. ej. RAILWAY.md) con tabla de variables y perfiles.
- Prueba manual: indexar un repo de prueba con código y al menos un PDF en el repositorio; verificar respuestas RAG coherentes.
```

---

## 3. Descripción general del proyecto

**DocViz (Sesión 1)** es un asistente basado en **RAG**: el sistema **no** está pensado para que el usuario suba un PDF suelto como paso principal de carga. En su lugar, permite **conectar y trabajar sobre un repositorio Git completo** alojado en el servidor: se explora el árbol de archivos, se lee el contenido en la interfaz y se **indexa el código (y otros documentos del repo) en Pinecone** para responder preguntas con contexto recuperado.

Si el repositorio incluye **archivos PDF** (u otros formatos que el backend sepa interpretar o extraer como texto), esos contenidos pueden **incorporarse al mismo pipeline de fragmentación, embeddings y almacenamiento en Pinecone**, de modo que el asistente también pueda “leer” y razonar sobre ellos **en el contexto del proyecto**, no como un PDF aislado cargado desde la UI.

En resumen: la **unidad de trabajo es el repositorio**; los PDF dentro del repo forman parte del corpus indexable, no un flujo alternativo de “solo PDF”.

---

## 4. Visión a futuro

La evolución natural del proyecto es convertirlo en un **asistente para resolver tickets de soporte** vinculados a **un repositorio concreto** (el producto o el código bajo mantenimiento). La idea es combinar:

- el **contexto técnico vivo** del repo (código, docs, PDFs incluidos en el proyecto), y  
- una **base de tickets ya resueltos** (preguntas frecuentes, incidencias cerradas, soluciones documentadas),

de forma que el sistema actúe como **memoria de soluciones aprendidas**: al atender un ticket nuevo, podría recuperar no solo fragmentos del código, sino **patrones de resolución** probados en casos anteriores. Esa capa de “tickets históricos como memoria” es **funcionalidad prevista, aún no implementada** en esta sesión; aquí el foco está en RAG sobre el repositorio y el despliegue en Railway.

---

*Referencia del tutorial del curso: agentes de coding, Pinecone, despliegue en Railway ([Railway Agents](https://railway.com/agents)).*
