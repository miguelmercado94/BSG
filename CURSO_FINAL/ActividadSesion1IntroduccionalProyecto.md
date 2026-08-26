# Actividad – Sesión 1: Introducción al proyecto

**Nombre:** Miguel Angel MErcado Tirado  
**Fecha:** 13/07/2026  

---

## Objetivo
Analizar un problema de negocio y aplicar los conceptos vistos durante la sesión para identificar un caso de uso de IA generativa, los requerimientos iniciales, una estimación básica de recursos y el alcance del proyecto.

## Caso
El área de Talento Humano de una empresa recibe diariamente decenas de consultas sobre vacaciones, permisos, beneficios y políticas internas. Las respuestas se entregan por correo electrónico y el tiempo promedio de atención supera las 24 horas. La dirección propone evaluar una solución basada en IA generativa para mejorar el servicio a los colaboradores.

---

## Desarrollo de la Actividad

### 1. Identificación del problema
*Describa brevemente cuál es el problema de negocio que debería resolverse y mencione al menos dos evidencias que permitirían demostrar que realmente existe.*

**Respuesta:**
El problema central de negocio radica en la **ineficiencia operativa y los prolongados tiempos de respuesta** del departamento de Talento Humano frente a las consultas de los colaboradores (vacaciones, permisos, beneficios y políticas). Esta situación afecta la satisfacción interna y consume recursos que podrían orientarse a tareas estratégicas. 

A nivel operativo y legal, el problema se profundiza debido a:
* **Complejidad y flujos de aprobación:** Los procesos de Talento Humano no son directos; requieren pasos intermedios y aprobaciones jerárquicas (por ejemplo, la autorización previa del jefe inmediato para permisos y licencias).
* **Riesgo de incumplimiento regulatorio:** Existe una falta de control proactivo sobre situaciones sensibles, como la acumulación de periodos vacacionales no tomados por los empleados durante uno o más años, lo cual expone a la empresa a contingencias y sanciones legales según la normativa laboral.

**Evidencias de la existencia del problema:**
1. **Evidencia de desempeño (Lentitud):** El tiempo promedio de resolución y respuesta a través de correo electrónico supera las 24 horas.
2. **Evidencia de demanda (Saturación):** La recepción diaria de decenas de consultas sobre temas recurrentes evidencia la falta de un canal de autoservicio eficiente, saturando la capacidad del equipo de Talento Humano.

---

### 2. Objetivo del caso de uso
*Escriba un objetivo claro para este proyecto alineado con una necesidad del negocio.*

**Respuesta:**
Optimizar y diversificar el canal de comunicación del área de Talento Humano mediante la implementación de una solución automatizada e inteligente (asistente virtual/chatbot basado en IA generativa), con el fin de **reducir los tiempos de respuesta de más de 24 horas a minutos** para consultas frecuentes. Esto permitirá maximizar la eficiencia operativa del departamento, organizar de forma estructurada las solicitudes complejas y los flujos de aprobación (como permisos y vacaciones), y mejorar la experiencia de servicio y la satisfacción general de los colaboradores.

---

### 3. Requerimientos funcionales
*Proponga tres funcionalidades que la solución debería ofrecer.*

**Respuesta:**
1. **Asistente Virtual (Chatbot) para Consultas de Bajo Impacto y FAQs:** Automatización de respuestas a consultas frecuentes de los colaboradores basándose en las políticas internas y el manual del empleado (por ejemplo: días mínimos de vacaciones, código de vestimenta, beneficios corporativos, etc.), permitiendo resolver dudas recurrentes de forma inmediata.
2. **Clasificación de Correos y Validación Automatizada de Documentos (PDF):** 
   - Análisis y priorización automática de los correos electrónicos entrantes con base en la urgencia de la solicitud y el nivel jerárquico del remitente.
   - Procesamiento e interpretación de formatos de solicitud adjuntos (PDFs) para validar si están correctamente completados. En caso de detectar que un colaborador envía un formato mal requisitado en dos o más ocasiones, el sistema derivará de manera automática el caso a la bandeja de un analista de Talento Humano para atención personalizada.
3. **Sistema de Alertas Preventivas de Cumplimiento Legal e Interno:** Emisión de alertas proactivas al equipo de Talento Humano cuando se identifiquen riesgos de incumplimiento normativo o legal (por ejemplo, alertas sobre plazos límites para gozar de vacaciones acumuladas por más de un año, o cuellos de botella en la aprobación jerárquica de permisos).

---

### 4. Requerimientos no funcionales
*Proponga tres requisitos relacionados con rendimiento, seguridad, disponibilidad o escalabilidad.*

**Respuesta:**
1. **Rendimiento y Tiempos de Respuesta:** El sistema debe garantizar un tiempo de respuesta inmediato para interacciones directas con el chatbot (menor a 5 minutos para preguntas frecuentes). Para tareas complejas que impliquen el análisis de correos y adjuntos PDF, el procesamiento y la clasificación por prioridad no deberán exceder las 2 horas, reduciendo sustancialmente el tiempo de respuesta anterior de 24 horas.
2. **Seguridad, Confidencialidad y Control de Acceso:** 
   - El acceso al sistema estará restringido de forma exclusiva al personal de la organización mediante autenticación federada (SSO corporativo).
   - Se implementarán políticas estrictas de privacidad de datos y enmascaramiento de información sensible, garantizando que el modelo de IA no divulgue datos confidenciales de la empresa ni información personal identificable (PII) a colaboradores no autorizados.
3. **Disponibilidad Diferenciada y Escalabilidad:**
   - **Disponibilidad:** El chatbot interactivo debe garantizar una disponibilidad del 99% durante el horario laboral de la empresa. Por otro lado, el motor de análisis y clasificación de correos y documentos adjuntos debe operar en modalidad 24/7, permitiendo procesar y priorizar la bandeja de entrada durante los fines de semana y días no laborables.
   - **Escalabilidad:** La infraestructura del sistema debe ser elástica (basada en la nube), capaz de escalar automáticamente para soportar el incremento en el volumen de consultas y el crecimiento proyectado de la plantilla de colaboradores sin experimentar degradación en el rendimiento.

---

### 5. Recursos iniciales
*¿Qué recursos considera necesarios para iniciar el proyecto? Mencione aspectos de tiempo, personal, datos o infraestructura.*

**Respuesta:**
Para la viabilidad e inicio del proyecto, se contemplan los siguientes recursos requeridos:

1. **Infraestructura y Tecnología:**
   - **Orquestación y Pilotos:** Uso de la plataforma **n8n** para el diseño rápido de flujos de trabajo e integraciones tanto en fase piloto como en producción inicial para el chatbot y la clasificación de correos.
   - **Infraestructura Cloud:** Despliegue en la nube (ej. AWS EC2, API Gateway, etc.) para soportar la arquitectura avanzada del sistema de alertas en tiempo real.
   - **Modelos de Lenguaje (LLM):** Adopción de un modelo open-source eficiente y de tamaño optimizado (entre **8B y 16B de parámetros**) que cubra las necesidades de lenguaje de la organización.
   - **Hardware y Despliegue:**
     - *Fase piloto:* Uso de APIs externas para validación de concepto con costes variables mínimos.
     - *Producción:* Adquisición de hardware local de servidor dedicado (presupuesto estimado de **$30,000,000 COP**) para ejecutar los modelos open-source de forma local, garantizando la privacidad de los datos.

2. **Personal (Talento Humano del Proyecto):**
   - **Equipo Técnico:** 2 a 3 Ingenieros de Sistemas/Desarrolladores para encargarse del diseño de integraciones, desarrollo del chatbot, infraestructura en la nube y puesta en marcha.
   - **Experto de Dominio (Sponsor/Validador):** Al menos 1 profesional senior de Talento Humano para brindar soporte conceptual, definir las reglas de negocio y liderar la revisión y estructuración de los formatos internos de la empresa.

3. **Datos y Procesos:**
   - Recopilación, depuración y digitalización del manual de políticas corporativas, reglamento interno y FAQs.
   - Estandarización y formalización previa de formularios y formatos de solicitud (PDFs), garantizando que cuenten con campos claros que puedan ser leídos fácilmente por el sistema OCR/LLM.

4. **Tiempo:**
   - Plazo de desarrollo e implementación estimado de **4 a 6 meses** desde el kickoff y diseño de flujos hasta las pruebas de aceptación y salida a producción.

---

### 6. Delimitación del alcance
*Complete dos listas:*

#### Incluye:
- **Asistente Virtual (Chatbot - Prioridad Máxima):** Desarrollo del canal conversacional interactivo para resolver consultas de primer nivel. El alcance de respuestas estará acotado a un conjunto definido de políticas y preguntas frecuentes de alta demanda (ej. mínimos días de vacaciones, código de vestimenta, etc.) para asegurar efectividad inmediata y descongestión del correo corporativo.
- **Módulo de Clasificación y Análisis de Correos:** Implementación de un motor que analice la urgencia/prioridad de los correos entrantes y evalúe la correcta formalización de los adjuntos en formato PDF (validando firmas, fechas o campos mandatorios).
- **Escalamiento Inteligente:** Regla de derivación automática al equipo humano de Talento Humano cuando una consulta no esté en la base de datos o si un usuario adjunta un PDF mal requisitado más de dos veces consecutivas.

#### No incluye:
- **Sistema de Alertas Preventivas de Cumplimiento Legal:** Excluido para las primeras etapas (MVP) por su alto costo de desarrollo, requerimientos de infraestructura en la nube compleja (ej. AWS EC2, API Gateway) y su menor impacto operativo directo a corto plazo.
- **Trámite de Solicitudes Atípicas o Complejas:** No se responderán consultas personalizadas o fuera de la lista de temáticas prioritarias, las cuales continuarán siendo atendidas por correo convencional por analistas humanos.
- **Integraciones Transaccionales en Sistemas Core (ERP/Nómina):** El sistema operará como consultor documental y validador de formularios estáticos, sin ejecutar escrituras directas ni modificaciones en las bases de datos de Recursos Humanos (RH) durante esta fase.

---

### Reflexión final
*En no más de 150 palabras, explique por qué definir correctamente el problema de negocio es más importante que seleccionar una tecnología desde el inicio del proyecto.*

**Respuesta:**
Definir el problema de negocio permite a ingeniería dimensionar el alcance y la complejidad real de la solución. A veces, problemas aparentemente complejos se resuelven con tecnología simple y de rápido impacto, como usar n8n para orquestar el chatbot y clasificar correos en lugar de desarrollar código propio desde cero. 

Por el contrario, necesidades en apariencia sencillas pueden ser técnicamente exigentes: el sistema de alertas preventivas, simple en el papel, requiere arquitectura reactiva avanzada y análisis constante para evitar falsos positivos que saturen a Recursos Humanos. Sin una definición clara del problema, se corre el riesgo de subestimar desafíos técnicos críticos o de sobrediseñar soluciones simples, derivando en pérdidas de tiempo y presupuesto.
