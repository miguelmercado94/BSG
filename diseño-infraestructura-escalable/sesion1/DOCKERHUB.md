# Publicar imágenes en Docker Hub

Para **CI/CD automático** (GitHub Actions → Docker Hub → Railway al merge a `main`), ver [CI-RAILWAY.md](./CI-RAILWAY.md).

## Requisitos

1. Cuenta en [Docker Hub](https://hub.docker.com).
2. Iniciar sesión en la CLI:

   ```bash
   docker login
   ```

3. Ejecutar los comandos desde la carpeta **`Sesion 1`** (donde están `backend-sesion1/`, `frontend-sesion1/` y `back-security-sesion1/`).

Si `docker push` falla con *denied*, *unauthorized* o *context canceled*, ejecuta de nuevo `docker login` y comprueba que `TU_USUARIO` en las etiquetas coincide con tu ID de Docker Hub.

## Nombres de imagen

Por convención usamos:

| Imagen | Descripción |
|--------|-------------|
| `<usuario>/docviz-sesion1-backend` | API Spring Boot DocViz |
| `<usuario>/docviz-sesion1-frontend` | Nginx + SPA Vite |
| `<usuario>/docviz-sesion1-back-security` | Autenticación BSG (WebFlux + JWT, puerto **8081**) |

Sustituye `<usuario>` por tu ID de Docker Hub (ej. `miguelmercado94`).

## Comandos (`docker build` / `docker push`)

Sustituye `TU_USUARIO` y, si hace falta, el tag `latest`. Ejecuta desde la carpeta **`Sesion 1`**.

**Back-security** (Gradle `bootJar`, JRE 21; contexto = carpeta del módulo):

```bash
docker build -t TU_USUARIO/docviz-sesion1-back-security:latest -f back-security-sesion1/Dockerfile back-security-sesion1
docker push TU_USUARIO/docviz-sesion1-back-security:latest
```

**Backend DocViz** (misma imagen para Ollama o Gemini; en runtime: `SPRING_PROFILES_ACTIVE`, `GEMINI_*`, etc. en compose o Railway):

```bash
docker build -t TU_USUARIO/docviz-sesion1-backend:latest -f backend-sesion1/Dockerfile backend-sesion1
docker push TU_USUARIO/docviz-sesion1-backend:latest
```

**Frontend** (valores por defecto del Dockerfile: `/api` y `/security-api`, como en `docker-compose` con Nginx como proxy):

```bash
docker build -t TU_USUARIO/docviz-sesion1-frontend:latest -f frontend-sesion1/Dockerfile frontend-sesion1
docker push TU_USUARIO/docviz-sesion1-frontend:latest
```

**Frontend** (URLs absolutas sin reconstruir la imagen: al arrancar el contenedor, variables de entorno + `envsubst` generan `runtime-config.js`):

```bash
docker run -e BACKEND_URL=https://tu-api.example.com -e SECURITY_URL=https://tu-security.example.com/security-auth -p 3000:80 TU_USUARIO/docviz-sesion1-frontend:latest
```

Si prefieres fijar las bases en tiempo de build de Vite (sin variables al arrancar):

```bash
docker build --build-arg VITE_API_URL=https://tu-api.example.com --build-arg VITE_SECURITY_URL=https://tu-security.example.com/security-auth -t TU_USUARIO/docviz-sesion1-frontend:latest -f frontend-sesion1/Dockerfile frontend-sesion1
docker push TU_USUARIO/docviz-sesion1-frontend:latest
```

## Repositorios en Docker Hub

La primera vez que hagas `docker push`, Docker Hub puede crear el repositorio automáticamente (según permisos). También puedes crear antes los repos **docviz-sesion1-backend**, **docviz-sesion1-frontend** y **docviz-sesion1-back-security** como *public* o *private* desde la web.

## Etiquetas adicionales

Para versionar:

```bash
docker tag TU_USUARIO/docviz-sesion1-backend:latest TU_USUARIO/docviz-sesion1-backend:1.0.0
docker push TU_USUARIO/docviz-sesion1-backend:1.0.0
docker tag TU_USUARIO/docviz-sesion1-back-security:latest TU_USUARIO/docviz-sesion1-back-security:1.0.0
docker push TU_USUARIO/docviz-sesion1-back-security:1.0.0
```

## Nota sobre arquitecturas

Las imágenes se construyen para la **arquitectura de la máquina donde ejecutas `docker build`** (p. ej. `linux/amd64` en la mayoría de PCs y en muchos servidores). Si necesitas **multi-arch** (`arm64` + `amd64`), usa `docker buildx` con `--platform`; no está incluido por defecto en estos ejemplos.
