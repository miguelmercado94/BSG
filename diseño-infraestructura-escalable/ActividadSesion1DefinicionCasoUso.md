# PROJECT BRIEF · DOCVIZ (SOPORTE RAG MT)
## Definición y Diseño del Caso de Uso AI/LLM — Sesión 1

---

### 1. Declaración del Problema (Marco TADR)
*Delimitación diagnóstica del dolor de negocio con magnitudes verificables.*

* **Trigger (Gatillo)**: Asignación de un ticket de soporte técnico (Nivel 2 o 3) a un ingeniero de soporte para resolver un bug, responder consultas de código o configurar microservicios (frecuencia promedio: 3 a 5 asignaciones por día hábil por ingeniero).
* **Actor**: Ingeniero de soporte técnico / Desarrollador de Nivel 2 y 3.
* **Tarea hoy (AS IS)**: El ingeniero abre el ticket, identifica los microservicios, clona manualmente los repositorios de Git implicados en su máquina, realiza búsquedas de texto plano mediante IDE, busca manuales y diagramas en buckets S3 o wikis dispersas, y finalmente redacta la propuesta de solución técnica.
* **Dolor (con números)**: El proceso consume un promedio de **45 minutos por ticket** debido a la dispersión de información y código. Existe una tasa de reincidencia o error del **12%** por no consultar el histórico de tareas/soluciones técnicas similares documentadas en la base de datos documental.
* **Resultado deseado (con números)**: Reducir el tiempo promedio de procesamiento por ticket a menos de **15 minutos** (reducción del 66%) y disminuir la tasa de error técnico en las respuestas por debajo del **4%**.

---

### 2. Tipo de Tarea AI y Justificación
*Clasificación formal de la técnica a utilizar.*

* **Tipo de Tarea AI Seleccionada**: **RAG (Recuperación Aumentada por Generación)**.
* **Justificación**:
  * Es RAG porque el objetivo prioritario del sistema es responder consultas técnicas y explicaciones de código en lenguaje natural basándose en un corpus dinámico de datos propios (repositorios Git del cliente, documentación de soporte en S3 y base de datos relacional).
  * Se descartan las alternativas por las siguientes razones:
    * *Generación libre*: La salida debe estar estrictamente anclada a la realidad del código fuente y los documentos de soporte, no puede alucinar o inventar respuestas.
    * *Extracción estructurada*: La interacción principal del usuario es de tipo Q&A conversacional libre, no el mapeo de textos a esquemas de JSON con campos fijos.
    * *Clasificación semántica*: Se requiere resolver problemas y dar explicaciones detalladas, no catalogar los tickets con etiquetas cerradas.
    * *Summarization*: El rolling summary es una utilidad de persistencia secundaria, no el core del caso de uso.
    * *Agente*: En este MVP no se delega la toma de decisiones autónomas sobre sistemas transaccionales externos de producción.

---

### 3. Descomposición del Proceso (AS IS vs TO BE)
*Secuencia de etapas concretas indicando el alcance real de la intervención de IA.*

| Etapa | Cómo es hoy (AS IS) | ¿Interviene la IA? Qué cambiaría (TO BE) |
|---|---|---|
| **1. Creación de Tarea** | El ingeniero crea el ticket y busca manualmente en qué célula y repositorio reside el código afectado. | **No interviene.** Se gestiona mediante flujo estructurado en la interfaz de usuario de DocViz. |
| **2. Ingesta de Datos** | El ingeniero clona en su máquina e indexa mentalmente la estructura de directorios del repositorio. | **Sí interviene.** Al agregar un repositorio a la célula, el sistema de manera automática clona con JGit, segmenta en chunks, calcula embeddings y almacena los vectores en pgvector. |
| **3. Resolución de Consultas** | El ingeniero busca manualmente fragmentos de código e información en PDFs de soporte. | **Sí interviene.** El usuario utiliza el Chat RAG que realiza búsquedas semánticas y formula respuestas contextuales utilizando el LLM con las fuentes citadas. |
| **4. Registro e Historial** | El ingeniero resume a mano el progreso de la conversación y lo vincula al ticket de soporte. | **Sí interviene.** El servicio resumidor genera automáticamente un *rolling summary* (cada 20 mensajes) usando el LLM y lo guarda en MongoDB. |
| **5. Limpieza y Desasociación** | El ingeniero borra manualmente las carpetas clonadas para no saturar espacio. | **Sí interviene.** Al borrar una célula, se ejecuta un proceso en cascada que desasocia los repositorios y, si quedan huérfanos, elimina su S3, metadatos y pgvector. |

---

### 4. Contrato de Entrada y Salida
*Definición formal del canal de comunicación del sistema.*

* **Entrada**: Pregunta técnica en lenguaje natural (string), `taskId` de la tarea de soporte (UUID string), `conversacionId` (UUID string), y opcionalmente referencias contextuales con `@ [repo:filename]`.
* **Salida**: Stream progresivo de tokens en formato Server-Sent Events (`text/event-stream`). Al finalizar, se persiste en la colección `tareas` (MongoDB) un objeto JSON de tipo `MensajeChatDocumento` bajo el siguiente esquema:
  * `texto_entrada` (string): Pregunta original.
  * `texto_respuesta` (string): Respuesta técnica final formulada.
  * `fecha_respuesta` (date): Fecha del servidor.
  * `hora_respuesta` (date): Timestamp detallado de la respuesta.
* **Ejemplo concreto entrada → salida**:
  * **Entrada**: `"@[repo:docker-compose.yml] describe los servicios principales"`
  * **Salida**:
    * *Stream SSE*: `data:El ` `data:archivo ` `data:define ` ...
    * *Persistencia final*:
      ```json
      {
        "texto_entrada": "@[repo:docker-compose.yml] describe los servicios principales",
        "texto_respuesta": "El archivo docker-compose.yml define 6 servicios: bsg-mongo (base de datos documental), bsg-postgres-docviz (base relacional y vectorial pgvector), bsg-redis (memoria en caché), bsg-localstack (emulador local de AWS S3), bsg-eureka (servidor de descubrimiento) y bsg-soporte-rag-mt (núcleo del motor RAG).",
        "fecha_respuesta": "2026-08-17T00:00:00.000Z",
        "hora_respuesta": "2026-08-17T13:56:01.325Z"
      }
      ```

---

### 5. Métricas de Éxito en Cuatro Niveles
*Definición conceptual y cuantitativa para evaluar el rendimiento.*

| Nivel | Métrica Primaria | Umbral Aceptable | Umbral Aspiracional | Método de Cálculo / Responsable |
|---|---|---|---|---|
| **Negocio** | Tiempo promedio de resolución de tickets (MTTR). | 15 minutos. | 10 minutos. | Promedio de diferencia entre creación e inicio de la tarea y su cierre en la BD. Calculado semanalmente. |
| **Producto** | Tasa de aceptación de las respuestas del RAG. | 80% de respuestas útiles. | 90% de respuestas útiles. | feedback explícito recolectado en UI (pulgar arriba/abajo o reutilización del texto) por el usuario. |
| **Modelo / AI** | Fidelidad (Faithfulness) y Relevancia del Contexto. | 85% en fidelidad. | 95% en fidelidad. | Evaluado usando Ragas / Langsmith en un eval set de 100 preguntas adversariales fijas. |
| **Infraestructura** | Latencia de inicio de Stream (TTFT) y Latencia p95. | TTFT < 1.5 seg. Latencia p95 < 25 seg. | TTFT < 0.8 seg. Latencia p95 < 15 seg. | Medición y métricas de rendimiento recolectadas automáticamente en Spring Actuator y logs. |

---

### 6. Criterios de Validación Operativa
*Restricciones que delimitan el diseño técnico.*

* **SLO de Latencia**: Para mantener la experiencia interactiva, la latencia de respuesta para el primer token (Time-To-First-Token) debe ser inferior a **2 segundos**.
* **Envelope de Costo**: Dado que el soporte manual es costoso, el costo del pipeline RAG (embeddings + llamadas a LLM) debe mantenerse por debajo de **$0.08 USD por pregunta**.
* **Comportamiento ante Incertidumbre**: Si el score de similitud vectorial de pgvector es inferior al umbral mínimo (0.68) o no se encuentran chunks relevantes, el RAG debe responder estrictamente: *"No encuentro información relevante en la base de datos de soporte para responder a tu pregunta"* en lugar de alucinar.
* **Observabilidad Mínima**: Se registrarán de forma obligatoria en la base documental: la pregunta del usuario, la respuesta generada, el identificador de la tarea, los chunks vectoriales recuperados, el modelo utilizado, el conteo exacto de tokens consumidos y el feedback explícito del usuario.
* **Restricciones Legales y de Privacidad**: El código del cliente y los manuales internos contienen propiedad intelectual. La API Key de OpenAI o Gemini se consume bajo cuentas corporativas empresariales con acuerdos estrictos de no-retención y no-entrenamiento de datos.

---

### 7. Inventario y Priorización de Fuentes de Datos
*Mapeo y evaluación de las fuentes en 7 dimensiones (Escala 1-5).*

1. **Código Fuente de Repositorios Git (Operación)**:
   * *Evaluación*: Completitud (5), Frescura (5), Exactitud (5), Consistencia (4), Accesibilidad (5), Volumen (4), Legalidad (4).
   * *Prioridad*: **Alta**. Fuente indispensable para resolver las consultas del ticket.
2. **Documentación Técnica de Soporte en S3 (Auxiliar)**:
   * *Evaluación*: Completitud (4), Frescura (3), Exactitud (4), Consistencia (3), Accesibilidad (4), Volumen (3), Legalidad (4).
   * *Prioridad*: **Alta**. Aporta el contexto arquitectónico que no siempre está explícito en el código.
3. **Historial de Respuestas y Chat (Feedback/Evaluación)**:
   * *Evaluación*: Completitud (2), Frescura (4), Exactitud (4), Consistencia (5), Accesibilidad (5), Volumen (2), Legalidad (5).
   * *Prioridad*: **Media**. Se construirá un set de evaluación de **100 preguntas-respuestas reales** etiquetadas en la sesión 2 para validar la precisión del RAG.

---

### 8. Riesgos y Mitigaciones
*Identificación de los fallos más probables y planes de acción.*

* **Riesgo 1: Variabilidad en formatos de repositorios**: Estructuras no estandarizadas pueden degradar el chunking y la precisión semántica.
  * *Mitigación*: Implementación de un pipeline de segmentación específico por tipo de extensión de archivo (`FiltroArchivosUtil.java`) y testeo iterativo sobre el set de evaluación.
* **Riesgo 2: Tiempos de respuesta lentos por parte del LLM**: Latencias altas que afecten el SLO.
  * *Mitigación*: Implementar respuestas en formato streaming mediante Server-Sent Events (SSE) y caché de consultas frecuentes (Redis).
* **Riesgo 3: Formatos rotados o escaneados de mala calidad en S3**: Archivos de soporte que no se pueden leer como texto plano.
  * *Mitigación*: Agregar un paso de pre-procesamiento e integración de OCR en el pipeline de carga a S3.

---

### 9. Suposiciones Explícitas
*Hipótesis y premisas asumidas por el equipo de diseño.*

1. Se asume que el ochenta por ciento de la documentación en S3 y del código del repositorio está en formato legible por texto plano (UTF-8) o extensiones estándares compatibles.
2. Se asume que el uso de llaves corporativas de API (OpenAI/Gemini) cumple con las normativas locales de privacidad de la organización.
3. Se asume que el equipo técnico (desarrolladores de soporte) colaborará en el etiquetado inicial y la calificación de las respuestas durante las fases de testeo para calibrar el RAG.
