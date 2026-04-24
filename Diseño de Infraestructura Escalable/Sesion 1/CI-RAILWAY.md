# CI/CD: GitHub Actions → Docker Hub → Railway

Este documento describe el flujo típico. Los **workflows de GitHub Actions no se versionan** en este repositorio (carpeta `.github/workflows/` ignorada en Git); si quieres Actions, copia un YAML propio a tu fork o mantenlo solo en tu máquina.

Flujo de referencia al integrar en `main`:

1. Ejecutar **tests del backend** (`mvn test`) y **del frontend** (`npm run lint`, `npm run test`, `npm run build`).
2. Si cambió código bajo `backend-sesion1/**`, construir la imagen del **backend**, subirla a Docker Hub y llamar al **deploy hook del backend** en Railway.
3. Si cambió código bajo `frontend-sesion1/**`, hacer lo mismo con el **frontend**. En Railway suele bastar una sola imagen y fijar `BACKEND_URL` / `SECURITY_URL` en el servicio; si tu pipeline prefiere build-time, usa `VITE_API_URL` / `VITE_SECURITY_URL` en `docker build` (ver [DOCKERHUB.md](./DOCKERHUB.md)).

Los **pull requests** hacia `main` pueden limitarse a tests (sin publicar imágenes ni redeploy), según cómo configures tu workflow.

## Secretos en GitHub (Settings → Secrets and variables → Actions)

| Secreto | Descripción |
|--------|-------------|
| `DOCKERHUB_USERNAME` | Usuario de Docker Hub. |
| `DOCKERHUB_TOKEN` | Token de acceso (Docker Hub → Account Settings → Security → New Access Token). |
| `RAILWAY_DEPLOY_HOOK_BACKEND` | *(Opcional)* URL del deploy hook del **servicio backend** en Railway. |
| `RAILWAY_DEPLOY_HOOK_FRONTEND` | *(Opcional)* Igual para el **servicio frontend**. |

## Deploy hooks en Railway

1. En Railway: abre el **servicio** (backend o frontend).
2. **Settings** → **Deploy** → **Deploy Hooks** → **Generate Hook**.
3. Copia la URL y pégala en el secreto correspondiente de GitHub.

Cada POST a esa URL dispara un nuevo despliegue. Si el servicio usa imagen desde Docker Hub, alinea el tag con el que publicas (p. ej. `latest`).

## Conexión con Docker Hub en Railway

Si el servicio despliega desde **Docker Hub**, tras el `docker push` el hook fuerza un redeploy. Comandos manuales de build/push: **[DOCKERHUB.md](./DOCKERHUB.md)**.

## URLs del API y del security en el frontend

Opción recomendada: imagen sin build-args y, en Railway, variables `BACKEND_URL` y `SECURITY_URL` (sin barra final). Alternativa: en el job de `docker build`, pasa `--build-arg VITE_API_URL=…` y `--build-arg VITE_SECURITY_URL=…` (ver [DOCKERHUB.md](./DOCKERHUB.md)).
