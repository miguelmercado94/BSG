# MVP — Asistente de Soporte Técnico Cognitivo RAG (DocViz)
## Entrega Final: Transición del PoC al MVP en Producción

**Curso:** AI Project / AI Data Engineer — BSG Institute  
**Autor:** Miguel Ángel Mercado Tirado  
**Fecha:** Septiembre 2026  
**Repositorio del Proyecto (Código Fuente):** [`https://github.com/miguelmercado94/BSG.git`](https://github.com/miguelmercado94/BSG.git)  
**Rama de Despliegue / Producción:** `deploy-railway`  
**Repositorio Base de Demostración (Indexación):** [`https://github.com/miguelmercado94/awscore.git`](https://github.com/miguelmercado94/awscore.git) (Rama: `main`)  
**URL de la Aplicación en Producción (Frontend):** [https://frontend-production-e39d6.up.railway.app/](https://frontend-production-e39d6.up.railway.app/)  
**URL del API Gateway (HTTPS / WSS):** [https://api-gateway-production-867c.up.railway.app](https://api-gateway-production-867c.up.railway.app)

---

## 1. Resumen Ejecutivo y Propósito de la Entrega

Este proyecto representa la evolución completa desde el **Proof of Concept (PoC)** desarrollado en Jupyter Notebook ([`PoC_SoporteRAG_Simplificado_Miguel_Mercado.ipynb`](../PoC_SoporteRAG_Simplificado_Miguel_Mercado.ipynb)) hacia un **Minimum Viable Product (MVP) Cloud-Native**, robusto, reactivo y desplegado en producción bajo una **Arquitectura Cognitiva Segregada** y una infraestructura escalable de microservicios.

El sistema permite a los ingenieros y agentes de soporte técnico de TI (Nivel 2 y 3) interactuar en lenguaje natural a través de WebSockets en tiempo real para:
1. **Diagnosticar incidencias técnicas y excepciones** en repositorios de software reales (demostrado con el repositorio `awscore`).
2. **Consultar conocimiento histórico y prevención** a partir de tickets resueltos en formato Markdown (`.md`).
3. **Ejecutar herramientas autónomas (Tool Calling)** para inspeccionar código fuente, validar dependencias en repositorios oficiales (Maven Central, NuGet, PyPI, npm) y consultar documentación técnica viva en la web (Oracle Docs, Microsoft Learn, Spring Docs, etc.) asociadas dinámicamente mediante **Tags**.
4. **Generar automáticamente propuestas de parches `.diff`** almacenados en buckets S3 para acelerar la remediación de bugs.

---

## 2. Accesos y Credenciales para Evaluación

Para facilitar la revisión y pruebas interactivas por parte del profesor y evaluadores, se han aprovisionado los siguientes accesos en la plataforma web desplegada:

| Rol | Usuario | Contraseña | Permisos y Alcance en la Plataforma |
| :--- | :--- | :--- | :--- |
| **Administrador** | `admin01` | `Admin123` | Gestión de células de desarrollo, registro y vinculación de repositorios Git, configuración de Tags y URLs de herramientas web, subida y embedding de documentos de soporte (`.md`). |
| **Soporte Técnico** | `soporte01` | `Soporte123` | Creación y gestión del ciclo de vida de tareas de soporte (HUs), activación de sincronización e indexación de código, interacción mediante chat en tiempo real con streaming y ejecución de herramientas. |

- **Página de Inicio de Sesión:** [https://frontend-production-e39d6.up.railway.app/login](https://frontend-production-e39d6.up.railway.app/login)

---

## 3. Del PoC al MVP: ¿Qué cambió y cómo evolucionó?

Siguiendo los lineamientos de la **Guía de Transición (Del PoC al MVP)** y la **Ficha de Arquitectura Cognitiva (Sesión 2)**:

| Dimensión | Proof of Concept (PoC) | MVP en Producción (Sesión Final) |
| :--- | :--- | :--- |
| **Entorno de Ejecución** | Notebook interactivo Python (`.ipynb`) secuencial y local. | Plataforma web multicapa desacoplada (Frontend React/Vite + Microservicios WebFlux reactivos). |
| **Orquestación y Razonamiento** | LangChain / LangGraph simple en Python. | **Spring AI** en Java 21 con integración nativa de **Tool Calling**, Function Calling reactivo y streaming SSE/WebSocket. |
| **Almacenamiento de Memoria** | Local efímero; una sola tabla de embeddings en memoria/Docker. | **Memoria Segregada Multicapa**: <br>• *Memoria de Trabajo:* Historial en memoria del WebFlux Event Loop.<br>• *Memoria Episódica (Caché):* Redis Cloud por tarea.<br>• *Memoria Documental:* MongoDB Atlas (células, repositorios, tags, tareas).<br>• *Memoria Semántica:* PostgreSQL + **pgvector** con tablas particionadas por fuente (`git_chunk` vs `soporte_chunk`). |
| **Autonomía del Agente** | Agente ReAct simple con prompt plano. | **Pipeline Cognitivo Híbrido**: Despacho de intención (`ANALIZAR` con modelo rápido) + Ejecución de herramientas y generación (`RESPONDER` con modelo avanzado). |
| **Manejo de Herramientas** | Script monolítico `requests.get`. | Herramientas empresariales modulares: extractor web DOM semántico agnóstico, cliente Maven Central/NuGet/PyPI, clonador JGit y generador de diffs con S3. |

---

## 4. Arquitectura de Modelos LLM, Configuración y Prompts

En la **Sesión 2 (Arquitectura Cognitiva)** se definió que la selección de modelos y prompts debe obedecer a un balance estricto entre **calidad de razonamiento, latencia (TTFT < 2s) y optimización de costos**:

```
                                      ┌─────────────────────────────────────────────────────────────┐
                                      │                      CONSULTA DE USUARIO                     │
                                      └──────────────────────────────┬──────────────────────────────┘
                                                                     │
                                                                     ▼
                                      ┌─────────────────────────────────────────────────────────────┐
                                      │                1. FASE DE ANÁLISIS E INTENCIÓN               │
                                      │             Modelo: gpt-3.5-turbo (Baja latencia)           │
                                      │    Determina: ¿Requiere RAG? ¿Requiere Tools? ¿Profundo?    │
                                      └──────────────────────────────┬──────────────────────────────┘
                                                                     │
                                      ┌──────────────────────────────┴──────────────────────────────┐
                                      │                                                             │
                                      ▼                                                             ▼
                        [Consulta simple directa]                                     [Diagnóstico / Tools / RAG]
                                      │                                                             │
                                      │                                                             ▼
                                      │                               ┌─────────────────────────────────────────────┐
                                      │                               │       2. RECUPERACIÓN Y ENRIQUECIMIENTO     │
                                      │                               │   • pgvector (Chunks Git + Tickets .md)     │
                                      │                               │   • Redis (Historial conversacional)        │
                                      │                               │   • Contexto de Tags y URLs Web vinculadas  │
                                      │                               └─────────────────────┬───────────────────────┘
                                      │                                                     │
                                      ▼                                                     ▼
                        ┌───────────────────────────────────────────────────────────────────────────────────┐
                        │                        3. FASE DE GENERACIÓN Y TOOL CALLING                       │
                        │                       Modelo: gpt-4o (Alta precisión y código)                    │
                        │             Invoca herramientas si es necesario (Maven, Web, S3 diffs)           │
                        └─────────────────────────────────────────┬─────────────────────────────────────────┘
                                                                  │
                                                                  ▼
                                      ┌─────────────────────────────────────────────────────────────┐
                                      │         RESPUESTA FINAL EN TIEMPO REAL (STREAMING TOKENS)   │
                                      └─────────────────────────────────────────────────────────────┘
```

### 4.1. Selección de Modelos
1. **Modelo de Análisis y Ruteo (`gpt-3.5-turbo`):**
   - **Por qué:** Tarea de baja complejidad semántica (clasificar si la pregunta requiere búsqueda en código, tickets históricos o herramientas externas). Ejecuta en < 400ms a una fracción del costo de tokens.
2. **Modelo de Razonamiento y Generación (`gpt-4o`):**
   - **Por qué:** Requiere alta fidelidad en generación de código fuente, comprensión profunda de patrones reactivos (WebFlux, Netty), capacidad estricta de **Tool Calling** (llamada a funciones con validación de esquemas JSON) y formateo de parches sin alucinaciones.
3. **Modelo de Embeddings (`text-embedding-3-small` a 768 dimensiones):**
   - **Por qué:** Ofrece un rendimiento de recuperación en similitud de coseno superior a modelos legacy, con un tamaño de vector optimizado (768d) que reduce el consumo de memoria en **pgvector** y permite búsquedas vectoriales por debajo de 50ms.

### 4.2. Parámetros de Inferencia
- **`temperature: 0.2`**: Se configuró una temperatura baja para garantizar determinismo, consistencia técnica en la sintaxis de código y evitar alucinaciones en diagnósticos de infraestructura.
- **`max-tokens: 4096`**: Límite suficiente para respuestas técnicas extensas que incluyan fragmentos de código completos o diffs estructurados.

### 4.3. Diseño de Prompts

#### Prompt de Sistema (`soporte-rag.prompt.sistema`)
```text
Eres un asistente de soporte técnico experto y multidisciplinario (.NET, Oracle PL/SQL, Java, Python, Cloud, etc.). 
Tu objetivo es responder con alta precisión técnica basándote en el contexto del repositorio y enriqueciendo tus 
respuestas consultando en línea las herramientas y URLs de documentación técnica asociadas a los tags del repositorio 
(usa 'consultarPaginaWeb' para páginas de documentación oficial, manuales, sintaxis y ejemplos de código, o 
'consultarDependenciasMaven' para dependencias Maven). Proporciona explicaciones claras, mejores prácticas y ejemplos 
de código cuando sea pertinente.
```

#### Prompt de Usuario y Contexto (`soporte-rag.prompt.usuario`)
```text
Usando el siguiente contexto, responde a la consulta del usuario.
---
Contexto: {contexto}
---
Consulta: {pregunta}
```
*Donde `{contexto}` se ensambla dinámicamente uniendo: fragmentos de código del repositorio indexado, casuísticas de tickets `.md`, historial de conversación y las herramientas web configuradas en los Tags.*

---

## 5. Arquitectura de Componentes en Railway (Cloud Topology)

El despliegue en [Railway](https://railway.app/) se estructuró bajo el principio de **aislamiento de red, mínimo privilegio y eficiencia de costos** (< $5 USD/mes):

```
                        ┌────────────────────────────────────────────────────────┐
                        │                    INTERNET PÚBLICA                    │
                        └───────────────────┬────────────────┬───────────────────┘
                                            │                │
                        HTTPS (Puerto 443)  │                │  HTTPS (Puerto 443)
                                            ▼                ▼
                     ┌───────────────────────────┐      ┌───────────────────────────┐
                     │    FRONTEND (React/Vite)  │      │   API-GATEWAY (Spring GW) │
                     │   Single Page Application │      │    Único punto expuesto   │
                     └───────────────────────────┘      └────────────┬──────────────┘
                                                                     │
═════════════════════════════════════════════════════════════════════╪═════════════════════════════════════
   RED PRIVADA INTERNA (*.railway.internal)                          │
═════════════════════════════════════════════════════════════════════╪═════════════════════════════════════
                                                                     │
                                            ┌────────────────────────┴────────────────────────┐
                                            │                                                 │
                                            ▼                                                 ▼
                             ┌─────────────────────────────┐                   ┌─────────────────────────────┐
                             │    BACK-SECURITY-SESION1    │                   │       SOPORTE-RAG-MT        │
                             │  Auth JWT, Roles, R2DBC     │                   │  Core RAG, Spring AI, JGit  │
                             └──────────────┬──────────────┘                   └──────────────┬──────────────┘
                                            │                                                 │
                     ┌──────────────────────┴──────────┬──────────────────────────────────────┼─────────────────────┐
                     │                                 │                                      │                     │
                     ▼                                 ▼                                      ▼                     ▼
        ┌─────────────────────────┐       ┌─────────────────────────┐            ┌─────────────────────────┐  ┌───────────┐
        │       POSTGRESQL        │       │       REDIS CLOUD       │            │      MONGODB ATLAS      │  │ MINIO S3  │
        │ • security_db (Auth)    │       │ Sesiones y Caché de HU  │            │ • celulas, repositorios │  │ Parches   │
        │ • rag_db (pgvector)     │       │ (Baja latencia)         │            │ • tags, tareas, soporte │  │ .diff     │
        └─────────────────────────┘       └─────────────────────────┘            └─────────────────────────┘  └───────────┘
```

### Componentes Clave:
1. **Frontend (`frontend`):** SPA desarrollada en React + Vite + TypeScript con diseño premium responsivo, gestión de estados de autenticación y cliente WebSocket para recepción de tokens por chunks.
2. **API Gateway (`api-gateway`):** Punto único perimetral expuesto a Internet. Valida firmas JWT en tiempo de ejecución, inyecta credenciales al backend mediante cabeceras seguras (`X-User-Id`, `X-User-Roles`) y rutea tráfico HTTP y WebSockets (`/ws/chat/**`).
3. **Servicio de Seguridad (`back-security-sesion1`):** Microservicio reactivo no bloqueante (WebFlux + R2DBC) conectado a la base de datos `security_db`.
4. **Servicio Core RAG (`soporte-rag-mt`):** Orquestador inteligente Spring AI. Integra clonación Git vía JGit, segmentación de código, cálculo de vectores, persistencia documental en MongoDB Atlas, almacenamiento en MinIO S3 y herramientas de inspección web.
5. **Capa de Datos:**
   - **PostgreSQL (Instancia compartida):** Aloja `security_db` y `rag_db` (con extensión `vector` habilitada).
   - **MongoDB Atlas:** Cluster Cloud M0 que almacena el modelo documental de la plataforma.
   - **Redis:** Caché caliente en memoria para acelerar la rehidratación del historial conversacional.
   - **MinIO:** Almacén S3 ultra-ligero para persistir borradores de parches y artefactos.

---

## 6. Guía de Pruebas Paso a Paso para el Evaluador

A continuación se detalla el flujo sugerido para validar el sistema de extremo a extremo utilizando el repositorio real y los tickets contenidos en esta carpeta:

### Paso 1: Configuración Inicial como Administrador
1. Inicia sesión en [DocViz](https://frontend-production-e39d6.up.railway.app/login) con el usuario:
   - **Usuario:** `admin01` | **Contraseña:** `Admin123`
2. **Crear una Célula de Trabajo:**
   - Haz clic en el botón `+` en la sección de Células.
   - **Código:** `CEL-001`
   - **Nombre:** `Célula Core AWS`
   - **Descripción:** `Equipo de desarrollo y soporte para servicios Cloud y autenticación`
   - Haz clic en **Continuar**.
3. **Configurar el Repositorio:**
   - **URL del Repositorio:** `https://github.com/miguelmercado94/awscore.git`
   - **Nombre:** `awscore`
   - **Rama principal:** `main`
4. **Configurar y Enlazar el Tag con la Herramienta en Línea:**
   - En el formulario inferior de Tags, crea o selecciona el tag:
     - **Tag:** `maven`
     - **Descripción:** `Repositorio oficial de librerías y dependencias Maven`
     - **URL de la Herramienta:** `https://mvnrepository.com/`
     - **Contexto:** `Consulta en vivo de versiones estables de dependencias Java/AWS`
   - Vincula el tag al repositorio y guarda los cambios.
5. **(Opcional) Subir Documento de Soporte:**
   - En la pestaña de **Soportes**, puedes crear un soporte y pegar el contenido de [`TICKET-001-login-null-npe.md`](./TICKET-001-login-null-npe.md) para registrar el antecedente en la base de conocimiento.
6. Cierra la sesión del administrador.

---

### Paso 2: Ejecución de Tareas y Chat con el Agente como Soporte
1. Inicia sesión con el usuario de soporte:
   - **Usuario:** `soporte01` | **Contraseña:** `Soporte123`
2. **Crear e Iniciar una Tarea:**
   - Crea una nueva tarea asignada a la célula `CEL-001` y al repositorio `awscore`.
   - **Título:** `Diagnóstico de incidencias en microservicios AWS`
   - **Estado:** Pasa la tarea de `BORRADOR` a **`INICIADA`**.  
     *(En este momento, el backend sincroniza el repositorio Git e indexa los vectores en pgvector).*
3. **Abrir el Chat Interactivo (WebSocket en tiempo real)** y probar los siguientes casos:

#### Caso de Prueba A: Diagnóstico de Excepción en Código (Basado en TICKET-001)
- **Pregunta para el chat:**
  > *"Al llamar a los endpoints de /login y /refresh en el servicio de autenticación recibo un error 500 con NullPointerException, pero el registro sí funciona. ¿Puedes revisar AuthServiceImpl, explicarme la causa raíz y generar una propuesta de parche .diff para corregirlo?"*
- **Resultado esperado del agente:**
  - Identifica que en WebFlux los métodos reactivos no deben devolver `null`.
  - Cita la ubicación exacta en `AuthServiceImpl.java`.
  - Explica la solución con `Mono.error(...)` o la implementación real con `passwordEncoder` y `tokenService`.
  - Ejecuta la herramienta de propuesta de modificación y genera un enlace presignado de S3 para el parche `.diff`.

#### Caso de Prueba B: Consulta Autónoma de Dependencias vía Tags (Herramienta Web)
- **Pregunta para el chat (sin escribir URLs en la pregunta):**
  > *"¿Cuál es la última versión disponible de la librería software.amazon.awssdk:s3 para actualizar nuestro pom.xml?"*
- **Resultado esperado del agente:**
  - El agente detecta de forma autónoma que el repositorio tiene vinculado el tag `maven` (`https://mvnrepository.com/`).
  - Invoca la herramienta de consulta web y recupera en tiempo real la versión estable más reciente (ej. `2.54.14`).
  - Genera el snippet de configuración XML para el `pom.xml` con el enlace oficial a Maven Central.

#### Caso de Prueba C: Rendimiento y Netty Event Loop (Basado en TICKET-003)
- **Pregunta para el chat:**
  > *"Bajo carga concurrente el documentservice se congela al subir archivos a S3 y bloquea los hilos de Netty. ¿Por qué ocurre esto en S3Adapter y cuál es la solución recomendada?"*
- **Resultado esperado del agente:**
  - Explica la saturación del Event Loop provocada por `S3Client` sincrónico.
  - Recomienda el desplazamiento a `boundedElastic` o la migración a `S3AsyncClient` con `Mono.fromFuture(...)`.

---

## 7. Estructura de Archivos de esta Entrega

```
CURSO_FINAL/
├── README_PoC_SoporteRAG.md                           # Documentación del PoC original (Sesión previa)
├── PoC_SoporteRAG_Simplificado_Miguel_Mercado.ipynb   # Notebook ejecutable del PoC
├── GuiaSesion2ArquitecturaCognitiva_md.md             # Especificación de la Arquitectura Cognitiva
├── GuiadelPoCalMVP_extracted.md                       # Lineamientos metodológicos de transición
└── tickets-awscore/                                   # Casos de prueba y base de conocimiento (.md)
    ├── README.md                                      # ESTE DOCUMENTO (Guía final de entrega y evaluación)
    ├── TICKET-001-login-null-npe.md                   # Caso: NPE en métodos reactivos de autenticación
    ├── TICKET-002-jwt-secret-base64.md                # Caso: Clave JWT en formato Base64 inválido
    ├── TICKET-003-s3client-bloqueante-webflux.md      # Caso: S3Client bloqueando hilos en Netty
    ├── TICKET-004-config-credenciales-aws.md          # Caso: Discrepancia de variables AWS entre servicios
    └── TICKET-005-debug-logs-r2dbc-ssl.md             # Caso: Modos SSL de R2DBC y exceso de logs debug
```

---

## 8. Conclusiones y Cumplimiento de Criterios

1. **Autonomía y Precisión:** El sistema combina la exactitud determinista de la recuperación vectorial sobre código y documentación histórica con la flexibilidad de razonamiento y uso de herramientas en vivo de GPT-4o.
2. **Genericidad:** La integración de herramientas web no está acoplada a una tecnología particular; soporta ecosistemas Java, .NET, Python, Node.js y documentación oficial mediante selectores DOM semánticos universales.
3. **Escalabilidad Cloud:** La solución opera 100% contenerizada en Railway cumpliendo con los presupuestos asignados, con separación clara de capas de persistencia y observabilidad reactiva.
