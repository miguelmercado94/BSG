# Proyecto Integrador – Entregable 1 (50%)
## Diseño y Planificación de una Solución AI/LLM

**Nombre:** Miguel Angel Mercado Tirado  
**Fecha:** 30/07/2026  

---

## Objetivo
El presente documento detalla el diseño, la planificación y la estrategia de implementación de una solución de software inteligente basada en Modelos de Lenguaje (LLM) e Inteligencia Artificial, orientada a resolver una problemática empresarial concreta: la ineficiencia y los elevados tiempos de respuesta en la resolución de incidentes repetitivos del área de soporte técnico de TI. La propuesta se fundamenta en una arquitectura de microservicios robusta y reactiva, empleando un pipeline RAG (Retrieval-Augmented Generation) optimizado para garantizar bajo costo operativo y alta escalabilidad en startups.

---

## Parte 1. Definición del caso

### 1.1 Problema de negocio
Las startups y áreas de soporte de TI enfrentan cuellos de botella críticos debido a la resolución de incidentes técnicos. El análisis, la ubicación del origen del fallo y el desarrollo de la solución para un ticket promedio de soporte técnico suele demandar entre 30 minutos y 2 horas de trabajo manual (o incluso más en incidentes atípicos).

Aunque la primera línea de soporte es atendida por ingenieros de nivel junior, la falta de herramientas centralizadas los obliga a escalar frecuentemente los incidentes a desarrolladores senior e ingenieros especializados. Dado que el tiempo del personal senior está altamente comprometido en el desarrollo de producto, esta dinámica:
* Eleva significativamente los costos operativos y de personal en el departamento de TI.
* Sobrecarga a los ingenieros de mayor jerarquía con tareas operativas y redundantes (ej. corrección manual de datos en bases de datos o variables de configuración).
* Alarga los tiempos finales de resolución de cara al usuario final y provoca que el conocimiento técnico de resolución quede disperso en chats, logs o correos sin estructurarse.

### 1.2 Objetivos del proyecto
* **Acelerar el diagnóstico de fallas (SLA):** Generar respuestas técnicas concretas, guías paso a paso y parches de código sugeridos en un plazo de 5 a 10 minutos, combinando la base de conocimiento vectorial de incidentes resueltos (.md) y el código fuente del repositorio enlazado.
* **Reducir escalamientos a ingenieros senior:** Empoderar a los agentes de soporte junior mediante el asistente RAG para que puedan resolver autónomamente incidentes recurrentes, minimizando las interrupciones al personal senior más especializado.
* **Optimizar costos operativos de TI:** Incrementar la eficiencia del personal del área de soporte técnico, disminuyendo la necesidad de contratar mayor personal dedicado y reduciendo los costos de resolución por ticket.
* **Estandarizar y capitalizar el conocimiento corporativo:** Diseñar un pipeline automatizado de ingesta que procese y vectorice el conocimiento documentado en archivos Markdown (`.md`) de casuísticas previas, transformándolos en un activo digital consultable en tiempo real.
* **Garantizar viabilidad económica (Bajo costo):** Desarrollar un sistema de bajo costo de infraestructura (local o híbrido) adecuado para los presupuestos acotados de las startups.

### 1.3 Actores del sistema
1. **Administrador / Líder de Célula (TI Admin):** Personal técnico responsable de configurar las células de trabajo, registrar y vincular los repositorios Git públicos, crear y catalogar etiquetas tecnológicas, y estructurar/subir los documentos de soporte en formato `.md` que alimentarán el RAG.
2. **Agente de Soporte (TI Support Agent):** Usuario final del sistema. Visualiza la bandeja de tareas asignadas a su respectiva célula e interactúa con el chat RAG interactivo para obtener de forma inmediata guías de resolución paso a paso y parches de código recomendados basados en el historial.

### 1.4 Requisitos funcionales (RF)
* **RF-01. Ingestión de Código desde Repositorios:** El sistema debe clonar, segmentar y vectorizar el código fuente de repositorios Git vinculados a las células de trabajo.
* **RF-02. Ingestión de Documentos de Soporte (.md):** Permitir la carga e indexación semántica de archivos Markdown (`.md`) que documenten casuísticas resueltas (bajo una plantilla estricta de problema, solución y dificultades) desde Amazon S3 al almacén vectorial.
* **RF-03. Motor de Búsqueda RAG Jerárquico (Segregado):** Ante una consulta, el motor RAG debe realizar búsquedas vectoriales segregadas: priorizando la coincidencia en la tabla de soporte de casuísticas y recurriendo a la tabla de código fuente únicamente como contexto secundario de apoyo.
* **RF-04. Interacción por Tareas con Respuestas Completas y Streaming:** Permitir la interacción conversacional basada en RAG asociada a una tarea en estado "Iniciada", ofreciendo respuestas síncronas tradicionales y respuestas en tiempo real mediante Server-Sent Events (SSE).
* **RF-05. Relación N:M Célula-Repositorio:** Habilitar que un repositorio Git sea indexado una sola vez en el almacén vectorial y vinculado flexiblemente a múltiples células de trabajo, optimizando el espacio y los costos de procesamiento de embeddings.

### 1.5 Requisitos no funcionales (RNF)
* **RNF-01. Arquitectura API-First Reactiva:** Todos los microservicios core deben desarrollarse con Spring WebFlux y persistencia reactiva, asegurando una arquitectura no bloqueante capaz de manejar múltiples streams de tokens concurrentes.
* **RNF-02. Persistencia Vectorial Nativa (pgvector):** El almacenamiento de embeddings vectoriales debe realizarse en PostgreSQL aprovechando la extensión `pgvector` para búsquedas semánticas eficientes mediante distancia de coseno.
* **RNF-03. Desacoplamiento de Modelos (Spring AI):** Implementar una capa de abstracción basada en Spring AI que permita alternar dinámicamente entre modelos locales (Ollama con Llama 3) y servicios en la nube (OpenAI, Anthropic) sin modificar la lógica de negocio.
* **RNF-04. Control de Acceso y Revocación Activa:** Restringir el acceso a los endpoints mediante tokens JWT y proveer un mecanismo de invalidación en tiempo real (lista negra) en Redis o AWS DynamoDB ante cierres de sesión (logout).

### 1.6 Alcance del sistema
* **Dentro de Alcance:**
  - Orquestación distribuida de microservicios con Eureka Server y API Gateway.
  - Ingesta y vectorización de código de repositorios Git y archivos de incidentes `.md`.
  - Chat interactivo RAG de bajo costo con soporte completo y streaming SSE.
  - Integración de almacenamiento de objetos con Amazon S3 (buckets de soporte, borradores y workarea).
  - Control de accesos unificado por JWT y revocación en tiempo real.
* **Fuera de Alcance:**
  - Automatización del despliegue de parches de código o ejecución automática de scripts SQL correctivos sin supervisión humana.
  - Conexión nativa e integración bidireccional con herramientas de tickets externas (como Jira, Service Desk o Zendesk) en la fase del MVP inicial.

---

## Parte 2. Planificación

### 2.1 Plan de trabajo (Marco ágil Scrum)
El proyecto se desarrollará bajo un marco de trabajo **Scrum**, estructurado en sprints de dos semanas, garantizando la retroalimentación continua del usuario experto (Sponsor/Líder de Soporte) como validador de los objetivos de negocio y la precisión del modelo de lenguaje.

* **Etapa 1. Diseño del Flujograma y Arquitectura (20% del esfuerzo):** Modelar el flujograma de datos del sistema, la topología de red y los componentes de microservicios reactivos. Diseñar los esquemas de bases de datos relacionales, documentales y vectoriales.
* **Etapa 2. Integración y Selección de IA (20% del esfuerzo):** Evaluar el costo-beneficio de los modelos del mercado. Configurar el entorno de desarrollo local (Ollama + Llama 3 14B) e integrar las conexiones hacia S3 y pgvector en PostgreSQL.
* **Etapa 3. Implementación y Pruebas (45% del esfuerzo):** Desarrollar la lógica core del microservicio `soporte-rag-mt`, codificar el pipeline de fragmentación (*chunking*), afinar los prompts y realizar pruebas funcionales UAT con el usuario experto de soporte para verificar la mitigación de alucinaciones y la reducción de tiempos.
* **Etapa 4. Documentación y Presentación (15% del esfuerzo):** Generar los manuales técnicos, guías de estandarización de Markdown para ingesta, documentar endpoints mediante OpenAPI/Swagger y preparar la demo técnica ejecutiva.

### 2.2 Cronograma y distribución de horas
Para un total de **640 horas hombre** estimadas en el proyecto:

| Etapa del Proyecto | Horas Estimadas | Porcentaje |
| :--- | :---: | :---: |
| **1. Diseño de Arquitectura y Definición** | 128 horas | 20% |
| **2. Integración de Sistemas y Datos** | 128 horas | 20% |
| **3. Implementación y Pruebas** | 288 horas | 45% |
| **4. Documentación y Presentación** | 96 horas | 15% |
| **TOTAL** | **640 horas** | **100%** |

### 2.3 Tecnologías preliminares seleccionadas
* **Capa Cliente (Frontend):** SPA React, TypeScript, Vite, TailwindCSS y servidor Nginx.
* **Descubrimiento y Puerta de Enlace (Infraestructura):** Spring Cloud Gateway y Eureka Discovery Server.
* **Seguridad y Autenticación:** Spring WebFlux, R2DBC PostgreSQL, JWT, Redis y Amazon DynamoDB.
* **Procesamiento RAG Core (`soporte-rag-mt`):** Java, Spring Boot 3, Spring AI, PostgreSQL (pgvector), MongoDB (metadatos relacionales) y AWS S3.
* **Ambiente Local:** Docker, Docker Compose, LocalStack (S3 simulado) y Ollama.

### 2.4 Gestión de riesgos iniciales
1. **Riesgo: Alucinaciones del LLM en la generación de scripts correctivos.**  
   *Mitigación:* Acompañamiento del usuario experto de soporte TI en cada sprint de Scrum para evaluar las respuestas del modelo y afinar system prompts. Adicionalmente, establecer un enfoque *human-in-the-loop*, donde el asistente sugiere pero requiere aprobación humana antes de ejecutar cambios.
2. **Riesgo: Formatos inconsistentes o información incompleta en los archivos de soporte `.md` cargados.**  
   *Mitigación:* Establecer un linter de Markdown y una validación rígida a nivel de API que rechace documentos que no contengan las secciones mandatorias (Enunciado, Solución, Clases y Dificultades).
3. **Riesgo: Consumo excesivo y facturación imprevista por llamadas a APIs en la nube en fases iniciales.**  
   *Mitigación:* Forzar el uso del perfil `local` con Ollama y el modelo Llama 3 14B para las fases de codificación y pruebas unitarias/integración, limitando el uso de APIs en la nube exclusivamente a la fase final de aceptación de usuario (UAT) en producción.

---

## Parte 3. Arquitectura

### 3.1 Diagrama de Componentes y Flujo RAG
El siguiente diagrama describe la arquitectura de microservicios reactivos y el flujo de ingesta y consulta vectorial:

```mermaid
graph TD
    classDef client fill:#f9f0ff,stroke:#d946ef,stroke-width:2px;
    classDef infra fill:#f0fDF4,stroke:#22c55e,stroke-width:2px;
    classDef database fill:#ffF7ED,stroke:#f97316,stroke-width:2px;
    classDef llm fill:#eff6ff,stroke:#3b82f6,stroke-width:2px;

    User([👤 Agente de Soporte]) -->|1. Consulta Chat| FE[💻 Frontend SPA - React]
    FE -->|2. HTTP Proxy| GW[⚡ API Gateway - Spring Cloud]
    
    subgraph ECOSISTEMA_MICROSERVICIOS [Ecosistema de Microservicios]
        GW -->|3. Valida JWT| SEC[🔒 back-security-sesion1]
        GW -->|4. Enruta Petición| CORE[⚙️ soporte-rag-mt]
        CORE -.-->|Consulta Registro| EUR[🔍 Eureka Server]
    end

    subgraph PERSISTENCIA [Capa de Persistencia e Ingesta]
        CORE -->|5. Consulta Embeddings| DB[(🐘 PostgreSQL + pgvector)]
        CORE -->|6. Recupera Metadatos| MONGO[(🍃 MongoDB)]
        CORE -->|7. Recupera Archivos .md| S3[(🪣 AWS S3 - Buckets)]
    end

    subgraph PROVEEDORES_LLM [Modelos de Lenguaje & Embeddings]
        CORE -->|8a. Perfil nube| OpenAI[☁️ OpenAI / Anthropic API]
        CORE -->|8b. Perfil local| Ollama[🐳 Ollama Local - Llama3 / nomic]
    end

    class User,FE client;
    class GW,SEC,CORE,EUR infra;
    class DB,MONGO,S3 database;
    class OpenAI,Ollama llm;
```

### 3.2 Justificación de decisiones técnicas
* **React + Vite en Frontend:** Ofrece un desarrollo rápido, carga ágil en navegador de recursos estáticos y facilidad de orquestación de llamadas asíncronas hacia el API Gateway.
* **Spring WebFlux (Reactivo):** Fundamental para soportar conexiones Server-Sent Events (SSE) y streaming sin saturar la pila de hilos de la JVM. Esto permite atender a más usuarios concurrentes con hardware limitado en la startup.
* **Almacén Vectorial pgvector en PostgreSQL:** Permite consolidar los datos relacionales tradicionales y los datos vectoriales dentro de la misma instancia de base de datos relacional de la compañía. Se evitan los costos de red, latencia y licenciamiento de bases de datos vectoriales propietarias o independientes (ej. Pinecone).
* **MongoDB para Gobernanza de Células:** Estructura ideal para el almacenamiento documental y de metadatos complejos (ej. relaciones N:M dinámicas entre células, repositorios y listado de archivos indexados) sin sobrecargar el motor relacional.

### 3.3 Flujo RAG (Retrieval-Augmented Generation) paso a paso
1. **Ingesta y Fragmentación (Chunking):** Los archivos Markdown de incidentes y el código fuente se dividen en fragmentos de tamaño controlado (ej. 500 caracteres con un solapamiento del 10% para conservar contexto).
2. **Generación de Embeddings:** Cada fragmento se convierte en un vector denso mediante el modelo de embeddings activo (en desarrollo local `nomic-embed-text` de 768 dimensiones; en producción `text-embedding-3-small` de OpenAI).
3. **Persistencia Segregada:** Los vectores de código fuente se guardan en la tabla `soporte_rag_git_chunk`, y los vectores de Markdown de casuísticas se almacenan en `soporte_rag_soporte_chunk`.
4. **Consulta y Similitud Vectorial:** La consulta del usuario se vectoriza en tiempo real. El motor busca los vectores con mayor similitud de coseno, priorizando siempre la tabla de soporte de casuísticas para extraer las soluciones humanas previas.
5. **Inferencia Enriquecida:** Los fragmentos con mayor similitud se inyectan en el system prompt de la IA. El LLM (`gpt-4o-mini` o `llama3.2`) procesa el prompt enriquecido y genera una respuesta clara y estructurada en Markdown para el agente de soporte.

### 3.4 Seguridad, costos e infraestructura local
* **Seguridad y Revocación JWT:** La autenticación federada se centraliza en `back-security-sesion1`. Al realizar el logout, el token JWT se registra de forma inmediata en una lista negra activa dentro de Redis (o DynamoDB en nube), invalidando su acceso en el Gateway de manera síncrona.
* **Infraestructura de Bajo Costo en Desarrollo:** Uso de contenedores Docker para LocalStack (S3 local) y Ollama para inferencia local de embeddings y chat, asegurando costos cero en la fase de construcción de la herramienta.

---

## Parte 4. Integración

### 4.1 Contratos API (Endpoints Core)

#### 1. Ingesta y Vectorización de Casos de Soporte (`/api/v1/soportes`)
* **POST `/api/v1/soportes` (Carga y Generación de Embeddings):**
  - *Cuerpo (JSON):*
    ```json
    {
      "nombre": "Resolucion de error de conexion DB",
      "urlRepo": "https://github.com/empresa/soporte-core",
      "contenidoMarkdown": "## Enunciado\n- Problema: Caida de pool de conexiones...\n## Solucion\n1. Reiniciar servicio...",
      "etiquetaTecnologica": "Java"
    }
    ```
  - *Respuesta (201 Created):*
    ```json
    {
      "codigo": "SOP-882",
      "nombre": "Resolucion de error de conexion DB",
      "estadoIndexacion": "COMPLETADO",
      "chunksGenerados": 4
    }
    ```

* **DELETE `/api/v1/soportes/{codigo}` (Eliminar Caso y Chunks):**
  - *Respuesta (200 OK):* Confirmación de la eliminación de los metadatos y borrado físico de los vectores en pgvector.

#### 2. Interacción de Chat RAG (`/api/v1/tareas/{codigoTarea}`)
* **POST `/api/v1/tareas/{codigoTarea}/chat` (Respuesta Completa):**
  - *Cuerpo (JSON):*
    ```json
    {
      "pregunta": "Cómo soluciono la caída de pool de conexiones?"
    }
    ```
  - *Respuesta (200 OK):*
    ```json
    {
      "respuesta": "De acuerdo con el registro de soporte SOP-882, la caida del pool se soluciona modificando la variable de timeout y reiniciando el servicio...",
      "fuentesRecuperadas": [
        "SOP-882 (Resolucion de error de conexion DB)"
      ]
    }
    ```

* **POST `/api/v1/tareas/{codigoTarea}/chat/stream` (Streaming en SSE):**
  - *Cuerpo (JSON):* Mismo request de pregunta.
  - *Respuesta (200 OK - `text/event-stream`):* Emisión reactiva token por token. Al finalizar, genera de forma interna y asíncrona un resumen rodante (*rolling summary*) de la sesión de chat.

### 4.2 Autenticación y Topología de Red
* **Flujo de Seguridad:** Las llamadas externas deben apuntar al API Gateway (puerto 8080). El Gateway redirige al microservicio de autenticación `/security-api/api/v1/auth/login` para validar credenciales y retornar el JWT. Peticiones subsiguientes deben incluir el token en la cabecera `Authorization: Bearer <token>`, validándose de forma automática contra la base de datos de tokens revocados.
* **Topología de Despliegue:** Red privada virtual (VPC) en AWS. El frontend se expone a internet a través de un Application Load Balancer (ALB). Los microservicios internos se comunican dentro de la subred privada utilizando balanceadores de carga de red (NLB) y descubrimiento dinámico gestionado por Eureka y AWS Cloud Map (`soporte-rag-mt.bsg.internal`).

### 4.3 Procesos síncronos y asíncronos
* **Procesos Síncronos:**
  - Login de usuarios, validación de firmas JWT e invalidación de sesiones en bases de datos rápidas.
  - Interacciones conversacionales en vivo mediante chat síncrono y streaming SSE.
  - Operaciones CRUD de gobernanza en células de trabajo y repositorios.
* **Procesos Asíncronos:**
  - Clonación en disco del repositorio Git, lectura de archivos y generación masiva de embeddings de código fuente.
  - Persistencia de archivos estructurados de soporte `.md` en buckets S3 en segundo plano.
  - Actualización asíncrona de resúmenes conversacionales (*rolling summary*) tras el cierre de streams.

---

## Parte 5. Despliegue inicial

### 5.1 Arquitectura de Infraestructura en AWS
* **AWS ECS Fargate:** Orquestación de contenedores en servidor serverless para eliminar la gestión manual de servidores EC2, albergando de forma aislada las cinco imágenes de microservicios.
* **RDS PostgreSQL con pgvector:** Instancia relacional administrada para almacenar la base relacional de negocio y los índices vectoriales de código y soporte.
* **AWS DynamoDB / Redis:** Tablas optimizadas para lecturas de baja latencia en la lista negra de tokens revocados de seguridad.
* **Buckets AWS S3:** Tres buckets de almacenamiento independientes para organizar y aislar documentos y recursos (`soporte`, `borradores` y `workarea`).
* **Cloud Map:** Gestión del descubrimiento y DNS interno para balanceo elástico de microservicios.

### 5.2 Endpoints de Verificación de Salud
* **Health Check Estándar:** `GET /actuator/health` en todos los contenedores de Spring Boot, consumido por las sondas de balanceo y ECS para determinar la vida de las tareas.
* **Salud del Pipeline RAG:** `GET /api/v1/infraestructura/salud` expuesto por `soporte-rag-mt`, que efectúa ping a PostgreSQL, verifica la extensión pgvector, confirma conexión con S3 y valida la respuesta del motor de embeddings (Ollama o API en la nube).

### 5.3 Plan de Pruebas Funcionales

#### Caso de Prueba 1: Autenticación, Acceso Seguro y Cierre de Sesión (Logout)
* **Objetivo:** Validar que solo usuarios con credenciales correctas obtengan tokens JWT válidos y confirmar que tras el cierre de sesión, el token quede inutilizado en el Gateway.
* **Entradas:** Petición POST de credenciales válidas a `/security-api/api/v1/auth/login`; posterior petición GET con el token obtenido; finalmente, llamada a POST `/security-api/api/v1/auth/logout`.
* **Resultado Esperado:** El login responde con HTTP 200 y entrega el JWT. El GET a recursos protegidos responde con HTTP 200. Tras el logout, el token se registra en Redis/DynamoDB; cualquier intento subsiguiente de usar ese token debe retornar HTTP 401 Unauthorized.

#### Caso de Prueba 2: Carga, Fragmentación y Vectorización de Documento (.md)
* **Objetivo:** Verificar que la carga de un archivo de incidentes `.md` resuelto genere correctamente los fragmentos y embeddings en la base vectorial pgvector.
* **Entradas:** Petición HTTP POST a `/api/v1/soportes` enviando un Markdown estructurado válido.
* **Resultado Esperado:** Estado HTTP 201 Created. El archivo se almacena en el bucket S3 de soporte y se crean los fragmentos en la tabla `soporte_rag_soporte_chunk` de pgvector. La base MongoDB debe mostrar el registro en estado `COMPLETADO`.

#### Caso de Prueba 3: Consulta Conversacional RAG con Recuperación de Contexto
* **Objetivo:** Comprobar que el motor RAG recupere el contexto específico indexado en la base de datos vectorial ante una pregunta del agente de soporte, inyectándola en el prompt del LLM.
* **Entradas:** Petición HTTP POST a `/api/v1/tareas/{codigoTarea}/chat` enviando la pregunta: "Cómo soluciono la caída de pool de conexiones?".
* **Resultado Esperado:** Estado HTTP 200 OK. La respuesta generada por la IA debe citar explícitamente el archivo de soporte (ej. "SOP-882") y describir las acciones detalladas (como reiniciar el servicio) especificadas en dicho Markdown.
