# Entrega — DocViz / BSG (Sesión 1)

**Asignatura:** Diseño de infraestructura escalable  
**Alcance:** Arquitectura del servicio en **AWS**, **uso de modelos de lenguaje y embeddings** en el pipeline RAG, cumplimiento de requisitos y referencias del código.

---

## Acceso rápido (leer primero)

| Qué | Enlace o dato |
|-----|----------------|
| **Aplicación DocViz (usuario final)** | [http://bsg-frontend-alb-2137705119.us-east-1.elb.amazonaws.com/](http://bsg-frontend-alb-2137705119.us-east-1.elb.amazonaws.com/) |
| **Vídeo demo (Google Drive)** | [DocViz — Sesión 1 (demo)](https://drive.google.com/file/d/1dmq_u4mbxH84YdbjFWH9rkdq_SFsAVGx/view?usp=sharing) |
| **Versiones finales desplegadas (ECS)** | **Frontend** `1.0.32` · **DocViz backend (soporte-rag-mt)** `0.1.0` · **back-security** `1.0.9` (coinciden con `version.txt` y tags en Docker Hub / Terraform). |
| **Usuarios de prueba** | `admin01` (clave: `Admin123`) / `soporte01` (clave: `Soporte123`). |

---

## 1. Resumen ejecutivo

El sistema **DocViz** es una aplicación **API-first** con una arquitectura de microservicios formada por las siguientes piezas desacopladas:

| Pieza | Rol |
|--------|-----|
| **Frontend** | SPA React + Vite; Nginx sirve estáticos y **proxifica** `/api` (enrutado a `soporte-rag-mt`) y `/security-api` (enrutado a `back-security`) a través del Gateway. |
| **eureka-server** | Servidor de descubrimiento (Eureka Server) que registra dinámicamente las instancias activas de los microservicios. |
| **api-gateway** | Spring Cloud Gateway; actúa como punto de acceso único público, enrutando dinámicamente las peticiones. |
| **back-security** | Autenticación (JWT), usuarios y roles; WebFlux + R2DBC; integración con Redis y DynamoDB para revocación de tokens. |
| **soporte-rag-mt** (Core) | API de dominio (reemplaza al antiguo `backend-sesion1` deprecado): Git, índice vectorial (**pgvector** en PostgreSQL), **RAG** (recuperación + generación con **Spring AI**), work area, soporte, S3, cabecera `X-DocViz-User`. |

El núcleo del curso respecto a **IA aplicada** está en el backend DocViz ([soporte-rag-mt](file:///c:/Users/ADMIN/Documents/BSG/diseño-infraestructura-escalable/sesion1/soporte-rag-mt)): **embeddings** para indexar fragmentos del repositorio y **modelo de chat** para responder con contexto recuperado (véase **sección 3**).

La infraestructura en **AWS** separa entrada pública (ALB, API Gateway) de **ECS Fargate**, Cloud Map, RDS, Redis, DynamoDB y S3, definida en **Terraform** (`terrafom-project/main.tf`). La elección de **AWS frente a Google Cloud** se argumenta en la **sección 4**.

---

## 2. Componentes de software (repositorio)

| Directorio | Tecnología | Responsabilidad |
|------------|------------|-----------------|
| `frontend-sesion1` | React, TypeScript, Vite | UI; login → `/security-api` y API DocViz → `/api` a través de `api-gateway`; cabeceras `X-DocViz-User` y rol. |
| `eureka-server` | Spring Cloud Discovery Server (Gradle) | Servidor de descubrimiento para registro dinámico de microservicios. |
| `api-gateway` | Spring Cloud Gateway (Gradle) | Puerta de entrada (puerto `8080`), enruta peticiones hacia `back-security` y `soporte-rag-mt` usando balanceo de carga. |
| `back-security-sesion1` | Spring WebFlux, R2DBC | Login, registro, JWT; prefijo `/security-auth` expuesto tras el Gateway. |
| `soporte-rag-mt` | Spring Boot 3, Maven, **Spring AI** | Core RAG, Git, **pgvector**, S3 y soporte; reemplaza al antiguo `backend-sesion1` deprecado. |

**Docker / versionado:** imágenes en Docker Hub; `version.txt` por módulo e imagen referenciada en Terraform (`locals` en `main.tf`).

---

## 3. IA generativa y RAG: embeddings, chat y perfiles Spring

Esta sección concentra lo pedido por el curso: **qué modelos usamos**, **para qué** y **cómo encajan en el flujo RAG**.

### 3.1 Idea general del pipeline RAG en DocViz

1. **Ingesta:** el texto del repositorio (y fuentes configuradas, p. ej. markdown de soporte en S3) se divide en fragmentos (**chunks**).
2. **Embeddings:** cada fragmento se vectoriza con el **modelo de embeddings** elegido y se guarda en **PostgreSQL con extensión pgvector** (búsqueda por similitud).
3. **Consulta:** la pregunta del usuario se embedding-a con el **mismo modelo familia/proveedor** que en indexación (coherencia dimensional y semántica).
4. **Recuperación:** se recuperan los **top-k** fragmentos más cercanos en el espacio vectorial.
5. **Generación:** esos fragmentos se inyectan como **contexto** en el prompt enviado al **modelo de chat**, que produce la respuesta final (con límites de historial y tamaño de contexto configurados en `application.properties`).

Todo el acoplamiento a proveedores externos está centralizado en **Spring AI** (`spring.ai.*`), lo que permite cambiar perfil sin reescribir la lógica de negocio del RAG.

### 3.2 Producción en AWS (perfil `pdn`)

En ECS el backend core (`soporte-rag-mt`) arranca con **`SPRING_PROFILES_ACTIVE=pdn`**. La configuración activa **OpenAI** para **chat y embeddings** vía API HTTPS (`api.openai.com`), sin Ollama en el contenedor (auto-config de Ollama excluida en `application-pdn.properties`).

| Rol | Modelo | Detalle |
|-----|--------|---------|
| **Embeddings** (índice + consulta RAG) | **`text-embedding-3-small`** | Modelo de embedding denso de OpenAI; dimensiones alineadas con **`docviz.vector.embedding-dimensions`** (p. ej. **768** en configuración actual para coincidir con el esquema pgvector). |
| **Chat** (respuesta al usuario con contexto recuperado) | **`gpt-4o-mini`** (por defecto) | Modelo conversacional vía Chat Completions; configurable con **`OPENAI_CHAT_MODEL`**. Límite de salida acotado con **`max-completion-tokens`** (p. ej. 8192) según API reciente. |

Variables típicas: **`OPENAI_API_KEY`** (y equivalentes Spring AI para chat y embedding); el mismo secreto alimenta chat y embeddings en producción.

**Por qué esta combinación para el curso:** separa claramente **representación vectorial** (embeddings baratos y estables para miles de chunks) de **razonamiento lingüístico** (chat que sintetiza respuestas con citas de contexto). Es el patrón estándar en aplicaciones RAG empresariales sobre Spring AI.

### 3.3 Desarrollo local (perfil `local`)

Para no depender de API de pago en cada máquina, el perfil **`local`** usa **Ollama**:

| Rol | Modelo por defecto |
|-----|-------------------|
| **Chat** | **`llama3.2`** (override `OLLAMA_MODEL`) |
| **Embeddings** | **`nomic-embed-text`** (768 dimensiones; debe coincidir con `docviz.vector.embedding-dimensions`) |

La URL de Ollama es configurable (`OLLAMA_BASE_URL`, típicamente `http://127.0.0.1:11434`).

### 3.4 Perfil intermedio `develop`

Similar a producción en cuanto a **OpenAI**: **`gpt-4o-mini`** para chat y **`text-embedding-3-small`** para embeddings (`application-develop.properties`), útil para entornos de integración sin ECS.

### 3.5 Relación con la infraestructura

- El task **soporte-rag-mt en ECS** tiene **más CPU y memoria** que el frontend porque **embeddings e inferencia** (y la ingesta de repositorios) concentran carga.
- Las **llaves de OpenAI** no se versionan: llegan por **Terraform / variables sensibles** al task definition o por secretos del entorno de CI/CD.
- **PostgreSQL + pgvector** es el almacén canónico del índice; la escalabilidad del **relleno del índice** y del **tráfico de chat** se apoya en escalar tasks ECS y dimensionar RDS según métricas.

---

## 4. Por qué AWS frente a Google Cloud Platform (GCP)

Elegimos **AWS** por criterios prácticos del curso, no porque sea intrínsecamente mejor que **GCP**: la arquitectura ya integraba ALB/NLB, ECS Fargate, API Gateway + VPC Link hacia NLB, RDS, ElastiCache, DynamoDB, S3 y Cloud Map con **Terraform** (`main.tf` en us-east-1), patrón documentado y alineado con el laboratorio docente; reproduir lo mismo en GCP supondría otro stack (p. ej. Cloud Run/GKE, balanceadores internos, Memorystore, Cloud SQL) y **otro ciclo de integración** sin sumar al objetivo pedagógico. Además el **chat y los embeddings** van por **OpenAI API** desde Spring, así que el modelo no viene de Bedrock ni de Vertex: la nube cubre sobre todo compute, red y datos ya montados en AWS. **GCP sería viable**, pero priorizamos centrarnos en **RAG, Spring AI y escalabilidad** en lugar de portar la topología a otro proveedor.

---

## 5. Infraestructura AWS (Terraform)

| Recurso | Uso en el proyecto |
|---------|---------------------|
| **ECS Fargate** (`bsg-cluster`) | Cinco servicios: `bsg-frontend-service`, `bsg-back-security-service`, `bsg-soporte-rag-mt-service`, `bsg-api-gateway-service`, `bsg-eureka-service`; logs en **CloudWatch** para cada uno de ellos. |
| **ALB** (`bsg-frontend-alb`) | Entrada HTTP pública hacia el task del frontend (target group puerto 80). |
| **NLB internos** | Balanceo TCP para los servicios de la VPC (Gateway en puerto `8080`, Eureka en `8761`, Security en `8081` y Core en `8090`). |
| **API Gateway HTTP API** | Rutas `/security-auth/{proxy+}` y `/docviz/{proxy+}` hacia el `api-gateway` interno → **HTTP_PROXY** + **VPC Link**. |
| **Cloud Map** (`bsg.internal`) | Registro de servicios DNS internos: `security.bsg.internal`, `soporte-rag-mt.bsg.internal`, `gateway.bsg.internal` y `eureka.bsg.internal`. |
| **RDS PostgreSQL** | Bases `bsg_security` y `docviz` (esta última con pgvector). |
| **ElastiCache Redis** | Utilizado por `back-security` para almacenar tokens o sesiones temporales. |
| **DynamoDB** (`bsg_revoked_tokens`) | Registro de tokens JWT revocados. |
| **S3** (tres buckets) | Soporte, borradores, work area de `soporte-rag-mt`. |
| **IAM** | Roles ECS y políticas IAM para DynamoDB y buckets S3. |

Outputs útiles: `frontend_alb_url`, `api_gateway_endpoint`, `rds_endpoint`, `redis_endpoint`, DNS de NLB, buckets S3.

---

## 6. Cómo cumplimos los requisitos de infraestructura escalable

### 6.1 Separación de responsabilidades y microservicios

- **Seguridad** y **DocViz** son **despliegues distintos**, prefijos HTTP claros (`/security-auth` vs `/docviz`).
- El **frontend** solo sirve UI y proxy; la **IA reside en el backend DocViz (`soporte-rag-mt`).**

### 6.2 Escalabilidad horizontal y desacoplamiento

- **ECS Fargate** permite escalar réplicas por servicio (el backend `soporte-rag-mt` puede escalarse según carga de **ingesta y chat**).
- **NLB**, **Cloud Map** y **API Gateway** desacoplan clientes de la ubicación exacta de los tasks.

### 6.3 Seguridad

- JWT en **back-security**; revocación en **DynamoDB**; secretos de OpenAI fuera del repo.

### 6.4 Persistencia y servicios gestionados

- **RDS + pgvector** para vectores y datos relacionales; **S3** para objetos; **Redis** para security.

### 6.5 Observabilidad

- **CloudWatch Logs** por servicio; health checks en balanceadores y ECS.

### 6.6 Infraestructura como código

- **Terraform** en `terrafom-project/main.tf`.

### 6.7 Experiencia de usuario

- **Mismo origen** en el ALB para la SPA; CORS en API Gateway para llamadas directas al endpoint público.

---

## 7. URLs de referencia (producción AWS)

Tras `terraform apply`, usar outputs:

- **SPA:** `frontend_alb_url`.
- **API HTTP:** `api_gateway_endpoint` — prefijos `/security-auth/...` y `/docviz/...`.

Las referencias principales están documentadas arriba en la tabla de **Acceso rápido**.

---

## 8. Despliegue de aplicación

- Build/push de imágenes según **DOCKERHUB.md**.
- Actualizar **task definitions** y servicios ECS; frontend con `DOCVIZ_UPSTREAM`, `SECURITY_UPSTREAM`, `NGINX_RESOLVER` acordes a Cloud Map.

---

## 9. Anexo para el evaluador: URL pública, vídeo en Drive y credenciales de prueba

*(Resumen inicial en **Acceso rápido**.)*

### 9.1 URL de la aplicación (usuario final)

DNS del ALB del frontend en AWS (`frontend_alb_url`).

| Campo | Valor |
|--------|--------|
| **URL pública DocViz (SPA)** | [http://bsg-frontend-alb-2137705119.us-east-1.elb.amazonaws.com/](http://bsg-frontend-alb-2137705119.us-east-1.elb.amazonaws.com/) |

---

### 9.2 Vídeo y versiones finales de los servicios

#### Vídeo (Google Drive)

Demostración de la plataforma (acceso público, login, flujos por rol, repositorio / RAG / chat). Enlace con permiso de visualización para evaluación:

| Campo | Valor |
|--------|--------|
| **Enlace al vídeo** | [Ver en Google Drive](https://drive.google.com/file/d/1dmq_u4mbxH84YdbjFWH9rkdq_SFsAVGx/view?usp=sharing) |

#### Versiones finales desplegadas (imágenes ECS / Docker Hub)

Referencias en Terraform (`terrafom-project/main.tf`, `locals`) y en cada `version.txt` del monorepo:

| Servicio | Tag / versión | Archivo `version.txt` |
|----------|----------------|------------------------|
| **Frontend** (Nginx + SPA) | **1.0.32** | `frontend-sesion1/version.txt` |
| **DocViz backend (soporte-rag-mt)** | **0.1.0** | `soporte-rag-mt/version.txt` |
| **back-security** | **1.0.9** | `back-security-sesion1/version.txt` |
| **api-gateway** | *latest* | — |
| **eureka-server** | *latest* | — |

Imágenes Docker Hub usadas por ECS: `mmercado94/frontend-sesion1:<tag>`, `mmercado94/soporte-rag-mt:<tag>`, `mmercado94/back-security-sesion1:<tag>`, `mmercado94/api-gateway:latest`, `mmercado94/eureka-server:latest` (mismo número que la tabla o última versión).

---

### 9.3 Credenciales para pruebas (`admin01` y `soporte01`)

Estos usuarios están definidos en el **seed** de desarrollo del microservicio de seguridad (`back-security-sesion1`, `data.sql`). **Antes de la demo**, comprobad que la base **RDS** del entorno desplegado los contiene (misma semilla o migraciones aplicadas).

| Usuario | Contraseña | Rol |
|---------|------------|-----|
| `admin01` | `Admin123` | Administrador (`ROLE_ADMINISTRATOR`) — flujo típico **admin/cells** |
| `soporte01` | `Soporte123` | Soporte (`ROLE_SUPPORT`) — flujo típico **support/cells** |

**Nota:** Son credenciales pensadas para **demostración académica**. En un despliegue real conviene **rotar contraseñas**, usar usuarios provisionados de forma controlada y **no** versionar secretos en repositorios públicos.

---

*Documento para entrega académica — alineado al repositorio, Spring AI y Terraform.*
