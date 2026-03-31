# Despliegue en Railway (DocViz — Sesión 1)

Guía para publicar **backend** y **frontend** por separado. Perfil recomendado en la nube: **Spring `develop`** (chat con **Google Gemini**); el JAR debe compilarse con el perfil Maven **`!local,develop`** (dependencia `spring-ai-starter-model-google-genai`).

Para **subir las imágenes a Docker Hub** (mismos Dockerfiles), ver [DOCKERHUB.md](./DOCKERHUB.md).

El **Nginx del frontend** solo sirve la SPA; no hace proxy a un host `backend` (en Railway no existe y Nginx fallaba al arrancar). El cliente llama al API en la URL absoluta de `VITE_API_URL`.

## Resumen

| Servicio   | Raíz en el repo (desde esta carpeta) | Dockerfile        |
|-----------|--------------------------------------|-------------------|
| Backend   | `backend-sesion1/`                   | `Dockerfile`      |
| Frontend  | `frontend-sesion1/`                  | `Dockerfile`      |

En Railway: crea **dos servicios** desde el mismo repositorio y en cada uno indica el **Root Directory** correspondiente.

---

## 1. Backend

### Build (Docker)

- **Dockerfile:** `backend-sesion1/Dockerfile`
- **Build argument** (obligatorio para Gemini):

  | Nombre             | Valor                 |
  |--------------------|-----------------------|
  | `MAVEN_PROFILES`   | `!local,develop`      |

  Si la interfaz no acepta `!`, usa comillas o la CLI de Railway. Con **Ollama** en local el valor por defecto del Dockerfile es `local`; en producción con Gemini **no** uses `local` en el build.

### Variables de entorno (runtime)

| Variable                      | Valor ejemplo / notas |
|-------------------------------|------------------------|
| `SPRING_PROFILES_ACTIVE`      | `develop`              |
| `GEMINI_API_KEY`              | API key de Google AI Studio |
| `GEMINI_MODEL`                | Opcional. Por defecto: `gemini-2.5-flash` (`application-develop.properties`) |
| `PINECONE_API_KEY`            | Necesaria para ingesta RAG y Pinecone |
| `PORT`                        | Railway lo inyecta; no hace falta fijarlo manualmente |

Opcional: revisa `backend-sesion1/src/main/resources/application.properties` por más propiedades `docviz.vector.*` si cambias índice o modelo de embeddings.

### Tras el deploy

Copia la **URL pública HTTPS** del backend (p. ej. `https://tu-api.up.railway.app`). La necesitas para el build del frontend.

---

## 2. Frontend

### Build (Docker)

- **Dockerfile:** `frontend-sesion1/Dockerfile`
- **Build argument:**

  | Nombre          | Valor |
|-----------------|--------|
| `VITE_API_URL`  | URL **completa** del backend **sin** barra final, p. ej. `https://tu-api.up.railway.app` |

Vite sustituye `VITE_API_URL` en tiempo de build; el cliente llama a `${VITE_API_URL}/connect/git`, `/tags`, etc. En Docker Compose local suele usarse `/api` y Nginx hace de proxy; **entre dos servicios de Railway** lo habitual es apuntar al dominio público del API.

### Orden recomendado

1. Desplegar y verificar el **backend** (health: el contenedor usa `GET /tags` con cabecera `X-DocViz-User`).
2. Desplegar el **frontend** con `VITE_API_URL` ya fijada a la URL del paso 1.

---

## 3. CORS

El backend permite orígenes `https://*.up.railway.app` (ver `WebConfig.java`). Si usas dominio custom, añade el patrón u origen correspondiente en código o variable de entorno en una futura mejora.

---

## 4. Referencia local

- `docker-compose.yml` en esta carpeta: backend + frontend con `VITE_API_URL=/api` y proxy Nginx. No sustituye la configuración de Railway; sirve para desarrollo local.

---

## 5. Checklist rápido

- [ ] Backend: `MAVEN_PROFILES=!local,develop` en el build Docker  
- [ ] Backend: `SPRING_PROFILES_ACTIVE=develop`, `GEMINI_API_KEY`, `PINECONE_API_KEY`  
- [ ] Frontend: `VITE_API_URL=https://…` (URL del backend)  
- [ ] Probar flujo: usuario → conectar repo → ingesta → consulta RAG  
