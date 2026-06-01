# Conexiones de Salida (Outbound) e Integraciones del Backend DocViz

Este documento detalla todas las dependencias externas y conexiones "de salida" que el microservicio `backend-sesion1` (DocViz) realiza hacia otras infraestructuras, APIs, bases de datos o el propio sistema operativo.

A diferencia de los endpoints entrantes (Inbound / REST API), esta documentación cubre **qué consume el backend** para cumplir sus funciones (RAG, vectorización, ingesta y almacenamiento).

---

## 1. Interfaz de Comandos del Sistema (Subprocesos Bash / CLI)

El backend DocViz interactúa directamente con el sistema operativo para ejecutar binarios, principalmente para descargar el código fuente de los repositorios configurados antes de vectorizarlos.

### 1.1. Git Clone (Proceso de Sistema OS)
* **Propósito:** Descargar el repositorio remoto (usualmente desde GitHub/GitLab) hacia una carpeta temporal (`workarea`) dentro del contenedor o servidor local, para luego procesar los archivos de texto, hacer *chunking* y extraer los embeddings.
* **Tipo de conexión:** Subproceso del Sistema Operativo (`java.lang.ProcessBuilder` o similar ejecutando comandos de terminal).
* **Requisito:** El binario `git` debe estar en el `PATH` del sistema.

**Request (Ejemplo de comando Bash ejecutado internamente):**
```bash
git clone https://github.com/usuario/mi-repositorio.git /tmp/docviz/workspace/borradores/usr123/repo
```

**Response (Salida del proceso):**
*   **Éxito:** Código de salida `0` (Exit code 0). Archivos escritos correctamente en el disco físico.
*   **Error:** Código de salida diferente de `0` (ej. Error de autenticación, repositorio no encontrado) y salida en `stderr` (`fatal: repository not found`).

---

## 2. Motores de Inteligencia Artificial (LLM & Embeddings)

Dependiendo del perfil de Spring Boot (`local` vs `pdn`/`develop`), el backend delega a diferentes proveedores la inteligencia artificial a través de **Spring AI**.

### 2.1. API de OpenAI (Perfil `pdn` / Producción)
* **Propósito:** Generar respuestas semánticas basadas en contexto (Chat) y calcular los vectores matemáticos de los textos (Embeddings).
* **Tipo de conexión:** REST / HTTPS externo (`api.openai.com`).
* **Modelos usados:** `gpt-4o-mini` (Chat) y `text-embedding-3-small` (Embeddings).

**Request (Ejemplo a `POST https://api.openai.com/v1/chat/completions`):**
```json
{
  "model": "gpt-4o-mini",
  "messages": [
    {
      "role": "system",
      "content": "Eres un asistente técnico. Responde basándote estrictamente en este contexto del repositorio: [TEXTO_INJECTADO_DEL_VECTOR_STORE]"
    },
    {
      "role": "user",
      "content": "¿Cómo funciona el proceso de logout?"
    }
  ],
  "max_tokens": 8192
}
```

**Response (Ejemplo JSON de OpenAI):**
```json
{
  "choices": [
    {
      "message": {
        "role": "assistant",
        "content": "El proceso de logout centraliza la lógica en la función `logoutSession()`..."
      }
    }
  ]
}
```

### 2.2. API de Ollama (Perfil `local` / Desarrollo)
* **Propósito:** Alternativa gratuita a OpenAI para entornos locales mediante LLMs de código abierto.
* **Tipo de conexión:** REST / HTTP local (`http://127.0.0.1:11434`).
* **Modelos usados:** `llama3.2` (Chat) y `nomic-embed-text` (Embeddings - 768 dimensiones).

**Request (Ejemplo a `POST http://127.0.0.1:11434/api/generate`):**
```json
{
  "model": "nomic-embed-text",
  "prompt": "Función para hacer un cierre de sesión seguro."
}
```

**Response (Ejemplo Array de floats):**
```json
{
  "embedding": [0.012, -0.045, 0.771, ...] 
}
```
*(Este array tiene exactamente 768 posiciones según `docviz.vector.embedding-dimensions=768`)*

---

## 3. Base de Datos Relacional y Vectorial (PostgreSQL + pgvector)

* **Propósito:** Almacenar datos transaccionales y, más importante, funcionar como **Vector Store** para búsqueda semántica por similitud utilizando la extensión `pgvector`.
* **Tipo de conexión:** TCP / Protocolo JDBC (`jdbc:postgresql://localhost:5432/docviz`).

**Request (Ejemplo Consulta SQL de Similitud - Búsqueda RAG):**
Cuando un usuario hace una pregunta, la pregunta se convierte en un vector, y el backend hace esta consulta a la base de datos:
```sql
SELECT id, metadata, content, embedding 
FROM docviz_vector_chunk 
ORDER BY embedding <=> '[0.012, -0.045, ...]' -- Operador de distancia coseno
LIMIT 6; -- Definido por docviz.vector.rag-top-k=6
```

**Response (Ejemplo):**
```text
| id | metadata                             | content                                 |
|----|--------------------------------------|-----------------------------------------|
| 1  | {"file":"SessionLogoutService.java"} | "El usuario realiza un clear de sesión" |
```
*Este contenido luego se envía al LLM como contexto.*

---

## 4. Almacenamiento de Objetos en la Nube (AWS S3 / LocalStack)

* **Propósito:** Administrar documentos de conocimiento Markdown (Soporte), así como gestionar el área de trabajo y borradores temporales.
* **Tipo de conexión:** Cliente AWS SDK para Java (REST / HTTPS).
* **Buckets involucrados:** `bsg-docviz-soporte-env`, `bsg-docviz-borradores-env`, `bsg-docviz-workarea-env`.

**Request (Ejemplo S3 PutObject - Subida de Markdown):**
El backend empaqueta el archivo y usa la API de S3 para depositarlo.
```http
PUT /soporte/mi-repositorio/logout-issue.md HTTP/1.1
Host: s3.us-east-1.amazonaws.com
x-amz-acl: private
Content-Type: text/markdown

[Contenido del archivo Markdown de soporte]
```

**Response (Ejemplo):**
```http
HTTP/1.1 200 OK
x-amz-version-id: 3/L4kqtJlcpXroDTDmJ+rmSpNdO
ETag: "d41d8cd98f00b204e9800998ecf8427e"
```

*Nota adicional:* El backend también se comunica con AWS STS/S3 para **firmar URLs temporalmente** (Presigned URLs con TTL de 3600s) y enviárselas al Frontend para que el navegador descargue/suba el archivo directamente.

---

## 5. Historial de Chat (Firebase Firestore)

* **Propósito:** Persistir el historial de los hilos de conversación de Chat RAG de los usuarios, ya que los LLMs (OpenAI/Ollama) son apátridas (stateless).
* **Tipo de conexión:** Firebase Admin SDK (Conexión gRPC / REST autenticada mediante archivo JSON de cuenta de servicio).
* **Ubicación en BBDD:** Colección `users/{userId}/messages`

**Request (Ejemplo de creación de registro en Firestore):**
El SDK convierte la llamada Java en una petición remota a los servidores de Google.
```json
{
  "fields": {
    "role": { "stringValue": "user" },
    "content": { "stringValue": "¿Qué hace SessionController?" },
    "timestamp": { "timestampValue": "2026-05-20T19:58:00Z" }
  }
}
```

**Response:**
Acuse de recibo de Firestore (Confirmación de escritura/`DocumentReference`).

---

## 6. Registro de Logística y Observabilidad (AWS CloudWatch)

* **Propósito:** Cuando la aplicación corre desplegada en ECS Fargate, el agente contenedor envía constantemente un streaming de la salida estándar (`stdout`/`stderr`) al recolector de logs de AWS.
* **Tipo de conexión:** Integración nativa del Docker Daemon (awslogs driver).
* **Ubicación:** Log Group `/ecs/bsg-backend`.

**Request (Payload del driver awslogs):**
Se envían de forma asíncrona mensajes como:
```text
"[INFO] 2026-05-20 19:58:00 --- c.b.d.service.SessionLogoutService : Limpiando Vectores del Namespace"
```

---

## Resumen del Flujo de Salida de DocViz en un proceso de Ingesta y Consulta

1. **Usuario manda un Github URL.**
2. **Backend -> Bash (`git clone`)**: Descarga código a S3 / Disco.
3. **Backend -> OpenAI / Ollama (API)**: Envía chunks del código para obtener los Embeddings numéricos.
4. **Backend -> RDS PostgreSQL**: Guarda los vectores.
5. **Usuario pregunta en el Chat.**
6. **Backend -> RDS PostgreSQL**: Busca contexto cercano al vector de la pregunta.
7. **Backend -> OpenAI / Ollama (API)**: Envía el Chat final pidiendo la respuesta explicada al humano.
8. **Backend -> Firebase**: Guarda la pregunta y la respuesta.