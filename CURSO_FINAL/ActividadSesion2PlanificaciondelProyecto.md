# Actividad – Sesión 2: Planificación del proyecto

**Nombre:** Miguel Angel Mercado Tirado  
**Fecha:** 20/07/2026  

---

## Objetivo
Elaborar una planificación inicial para un proyecto de IA generativa, tomando como base el caso de uso definido en la sesión anterior.

## Contexto del Proyecto (Sesión 1)
Solución de IA Generativa para la optimización de atención en el departamento de Talento Humano: Asistente virtual (chatbot) para consultas de políticas internas (RAG), clasificación inteligente de correos entrantes y procesamiento/validación automatizado de formularios en PDF para solicitudes de permisos y vacaciones.

---

## Desarrollo de la Actividad

### 1. Plan de trabajo
*Describa en una o dos frases qué espera lograr en cada una de las siguientes etapas: Diseño de arquitectura, Integración, Implementación y pruebas, Documentación y presentación.*

**Respuesta:**

* **Diseño de arquitectura:** Diseñar el flujograma del sistema (aprovechando n8n como orquestador) para obtener una visión general de los componentes y sus integraciones, permitiendo identificar posibles riesgos tempranamente y facilitando el mantenimiento y la calidad del sistema a futuro.
* **Integración:** Evaluar las ofertas de IA en el mercado y determinar los componentes externos necesarios frente a aquellos que deben desarrollarse internamente por motivos de seguridad, privacidad y presupuesto. Esto abarca el análisis costo-beneficio del modelo LLM (propiedad privada vs. open-source), así como sus opciones de despliegue e intermediación (proveedores de inferencia rápida como Groq, la nube o servidores locales) para conectarlos de forma eficiente con los sistemas de la empresa.
* **Implementación y pruebas:** Desarrollar los flujos de trabajo automatizados y afinar los prompts y parámetros del LLM mediante pruebas funcionales, de estrés y de mitigación de alucinaciones; asimismo, involucrar activamente al usuario experto de Recursos Humanos (RH) en las pruebas de aceptación (UAT) para evaluar si se cumplieron los objetivos del negocio: reducir el tiempo de atención de más de 24 horas a minutos en consultas frecuentes y descongestionar la carga operativa del equipo.
* **Documentación y presentación:** Consolidar los manuales técnicos de arquitectura y despliegue, la guía de usuario/operación para el equipo de Talento Humano y realizar la demostración ejecutiva (pitch/demo) ante los stakeholders demostrando la reducción de tiempos de atención.

---

### 2. Cronograma
*Distribuya las horas estimadas entre las etapas del proyecto e indique cuál considera que demandará mayor esfuerzo y por qué.*

**Respuesta:**

Para un proyecto proyectado a una duración estimada de **640 horas hombre** (aprox. 4 a 6 meses a tiempo parcial/medio equipo), la distribución de tiempo por etapa es la siguiente:

| Etapa del Proyecto | Horas Estimadas | Porcentaje |
| :--- | :---: | :---: |
| **1. Diseño de Arquitectura y Definición** | 128 horas | 20% |
| **2. Integración de Sistemas y Datos** | 128 horas | 20% |
| **3. Implementación y Pruebas** | 288 horas | 45% |
| **4. Documentación y Presentación** | 96 horas | 15% |
| **TOTAL** | **640 horas** | **100%** |

**Etapa que demandará mayor esfuerzo y justificación:**  
La etapa de **Implementación y Pruebas (45% - 288 horas)** demandará el mayor esfuerzo del proyecto. Esto se debe a que trabajar con modelos de IA generativa exige una fase intensiva de *Prompt Engineering*, ajuste fino de contextos RAG para evitar alucinaciones en respuestas sobre políticas laborales, y una exhaustiva validación en el análisis de archivos PDF (donde las estructuras de los formularios pueden variar o presentar errores de llenado). Además, las pruebas funcionales iterativas con el equipo de Talento Humano son críticas para ajustar los criterios de escalamiento al analista humano.

---

### 3. Tecnologías
*Mencione las herramientas, plataformas o servicios que considera apropiados para el proyecto. Explique brevemente por qué las seleccionó. No es necesario definir una arquitectura definitiva.*

**Respuesta:**

1. **n8n (Orquestador de Automatizaciones / Workflows):**  
   Plataforma de orquestación visual que simplifica la conexión de servicios, correos, conectores a LLM y lógica de flujos sin rehacer infraestructura básica.
2. **Modelos de Lenguaje (Llama 3 14B / Mistral / Anthropic / OpenAI):**  
   Uso de **Llama 3 (14B)** en fase de desarrollo y pruebas. Para producción, según el presupuesto disponible, se evaluará una combinación estratégica de modelos (Mistral, Anthropic u OpenAI) asignando a cada IA una función específica (clasificación de correos, chatbot o RAG).
3. **pgvector (Base de Datos Vectorial sobre PostgreSQL):**  
   Seleccionada por ser muy popular, estar bien documentada y ser la herramienta con la que el equipo de desarrollo tiene mayor familiaridad y dominio técnico.
4. **Módulo de Procesamiento e Interpretación de PDFs (n8n vs. Microservicio Java + Spring Boot):**  
   Se evaluará si el análisis de adjuntos en PDF puede gestionarse directamente con nodos de n8n o si requiere diseñar un microservicio dedicado en **Java + Spring Boot**. Dado que la mayoría del conocimiento estará digitalizado en `.md` y la conversión masiva de PDFs tendrá una baja frecuencia posterior, se analizará su pertinencia como un servicio independiente.
5. **Autenticación SSO y Control de Acceso (OAuth2 con Java + Spring Boot):**  
   Implementación del protocolo OAuth2 mediante **Java + Spring Boot**, aprovechando que es el lenguaje especializado del equipo de desarrollo para garantizar seguridad, autenticación e identidades federadas.

---

### 4. Riesgos iniciales
*Identifique al menos tres riesgos que podrían afectar el desarrollo del proyecto y proponga una acción preventiva para cada uno.*

**Respuesta:**

1. **Riesgo 1: Alucinaciones del LLM e información imprecisa sobre políticas internas.**
   - *Impacto:* Respuestas erróneas sobre días de descanso o beneficios pueden generar malestar en los colaboradores o problemas normativos para la empresa.
   - *Acción Preventiva:* Mitigar mediante el acompañamiento constante del usuario experto de Recursos Humanos (RH). Se recomienda adoptar un marco de trabajo ágil como **Scrum**, donde el experto de RH participe de forma permanente en las revisiones de cada sprint para validar la precisión de las respuestas del RAG y afinar las reglas de negocio del modelo.

2. **Riesgo 2: Baja calidad o heterogeneidad en los formatos de solicitudes PDF.**
   - *Impacto:* Falla en la extracción automatizada de datos por parte del OCR/LLM si los adjuntos son escaneados con baja resolución, incompletos o manipulados.
   - *Acción Preventiva:* Estandarizar previamente los formatos digitales de solicitud en plantillas PDF interactivos (con campos de formulario estructurados) y establecer una regla de validación inicial que descarte y alerte al usuario si el archivo no cumple los requisitos mínimos antes de procesarlo.

3. **Riesgo 3: Resistencia al cambio o falta de adopción por parte de los colaboradores y el equipo de Talento Humano.**
   - *Impacto:* Que los empleados continúen usando canales informales o que el equipo de RH perciba la solución como una amenaza a sus puestos.
   - *Acción Preventiva:* Involucrar activamente al personal de Talento Humano desde la etapa de diseño como validadores clave del sistema (co-creación) y ejecutar un plan de comunicación y capacitación que posicione al asistente como una herramienta de apoyo operativo para liberarlos de tareas repetitivas.

---

### 5. Reflexión
*¿Por qué considera importante actualizar el plan de trabajo conforme avanza el proyecto?*

**Respuesta:**  
Actualizar continuamente el plan de trabajo es vital porque los proyectos con IA generativa conllevan un alto grado de incertidumbre y aprendizaje empírico. En este contexto, incorporar **principios ágiles** —como la adaptación continua al cambio sobre un plan rígido y la retroalimentación iterativa— resulta indispensable: a medida que se interactúa con datos y usuarios reales emergen casos de borde (*edge cases*) o limitaciones en los modelos no previstos al inicio. Una planificación flexible permite reasignar esfuerzos a tiempo hacia tareas críticas (como el refinamiento del RAG), gestionar las expectativas del negocio y entregar valor funcional de forma incremental.
