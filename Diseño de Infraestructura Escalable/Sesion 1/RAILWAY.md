# Despliegue en Railway (DocViz — Sesión 1)



Guía para publicar **backend** y **frontend** por separado. En la nube suele usarse el perfil Spring **`develop`** (chat con **Google Gemini**). La imagen Docker del backend incluye ya Ollama y Gemini en el classpath; **no** hace falta un perfil Maven ni build-args especiales: basta con variables de entorno en runtime.



Para **subir las imágenes a Docker Hub** (mismos Dockerfiles), ver [DOCKERHUB.md](./DOCKERHUB.md).



El **Nginx del frontend** solo sirve la SPA; no hace proxy a un host `backend` (en Railway no existe y Nginx fallaba al arrancar). El cliente puede usar URLs absolutas inyectadas al arrancar (`BACKEND_URL`, `SECURITY_URL`) o las bases fijadas en el build de Vite (`VITE_API_URL`, `VITE_SECURITY_URL`).



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

- **Sin** build-args obligatorios: `docker build -f backend-sesion1/Dockerfile backend-sesion1` (ver [DOCKERHUB.md](./DOCKERHUB.md)).



### Variables de entorno (runtime)



| Variable                      | Valor ejemplo / notas |

|-------------------------------|------------------------|

| `SPRING_PROFILES_ACTIVE`      | `develop` (Gemini) o `local` (Ollama) |

| `GEMINI_API_KEY`              | Con `develop`: API key de Google AI Studio |

| `GEMINI_MODEL`                | Opcional. Por defecto: `gemini-2.5-flash` (`application-develop.properties`) |

| `PINECONE_API_KEY`            | Necesaria para ingesta RAG y Pinecone cuando corresponda |

| `PORT`                        | Railway lo inyecta; no hace falta fijarlo manualmente |



Opcional: revisa `backend-sesion1/src/main/resources/application.properties` por más propiedades `docviz.vector.*` si cambias índice o modelo de embeddings.



### Tras el deploy



Copia la **URL pública HTTPS** del backend (p. ej. `https://tu-api.up.railway.app`) y la del servicio **back-security** si el frontend debe llamarlo por dominio público (p. ej. `https://tu-security.up.railway.app/security-auth`).



---



## 2. Frontend



### Build (Docker)



- **Dockerfile:** `frontend-sesion1/Dockerfile`

- **Recomendado (una sola imagen):** no pases build-args; en Railway define **variables de entorno del servicio** para que al arrancar se genere `runtime-config.js`:

  - `BACKEND_URL`: URL **completa** del API DocViz **sin** barra final (mismo valor que antes iría en `VITE_API_URL`).

  - `SECURITY_URL`: URL base del micro de seguridad **sin** barra final (p. ej. `https://tu-security.up.railway.app/security-auth`).



Vite puede seguir usando `VITE_API_URL` / `VITE_SECURITY_URL` si las fijas en el build; si `BACKEND_URL` / `SECURITY_URL` vienen no vacías al arrancar el contenedor, tienen prioridad en el navegador.



### Orden recomendado



1. Desplegar y verificar el **backend** (health: el contenedor puede usar `GET /tags` con cabecera `X-DocViz-User`).

2. Desplegar el **frontend** con `BACKEND_URL` (y `SECURITY_URL` si aplica) ya definidas en el servicio Railway.



---



## 3. CORS



El backend permite orígenes `https://*.up.railway.app` (ver `WebConfig.java`). Si usas dominio custom, añade el patrón u origen correspondiente en código o variable de entorno en una futura mejora.



---



## 4. Referencia local



- `docker-compose.yml` en esta carpeta: backend + frontend con perfil `containerized`; Nginx usa `/api` y `/security-api`. Puedes sobreescribir con `FRONTEND_BACKEND_URL` / `FRONTEND_SECURITY_URL` en un `.env` de la carpeta **Sesion 1** si necesitas URLs absolutas en local.



---



## 5. Checklist rápido



- [ ] Backend: `SPRING_PROFILES_ACTIVE=develop`, `GEMINI_API_KEY`, `PINECONE_API_KEY` (u Ollama si usas `local`)

- [ ] Frontend: `BACKEND_URL=https://…` y `SECURITY_URL=https://…/security-auth` (o build-args `VITE_*` equivalentes)

- [ ] Probar flujo: usuario → conectar repo → ingesta → consulta RAG

