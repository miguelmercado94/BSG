# CI/CD: GitHub Actions → Docker Hub → Railway

Al hacer **merge/push a `main`**, el workflow [`.github/workflows/docviz-sesion1.yml`](../../.github/workflows/docviz-sesion1.yml):

1. Ejecuta **tests del backend** (`mvn -P local test`) y **del frontend** (`npm run lint`, `npm run test`, `npm run build`).
2. Si cambió código bajo `backend-sesion1/**`, construye la imagen del **backend**, la sube a Docker Hub y llama al **deploy hook del backend** en Railway.
3. Si cambió código bajo `frontend-sesion1/**`, hace lo mismo con el **frontend** (con `VITE_API_URL` apuntando al API público; ver variable en el workflow).

Los **pull requests** hacia `main` solo ejecutan los tests (no publican imágenes ni redeploy).

## Secretos en GitHub (Settings → Secrets and variables → Actions)

| Secreto | Descripción |
|--------|-------------|
| `DOCKERHUB_USERNAME` | Usuario de Docker Hub (ej. `mmercado94`). |
| `DOCKERHUB_TOKEN` | Token de acceso (Docker Hub → Account Settings → Security → New Access Token). |
| `RAILWAY_DEPLOY_HOOK_BACKEND` | *(Opcional)* URL del deploy hook del **servicio backend** en Railway. Si no está, se omite el redeploy tras el push. |
| `RAILWAY_DEPLOY_HOOK_FRONTEND` | *(Opcional)* Igual para el **servicio frontend**. |

## Deploy hooks en Railway

1. En Railway: abre el **servicio** (backend o frontend).
2. **Settings** → **Deploy** → **Deploy Hooks** → **Generate Hook**.
3. Copia la URL y pégala en el secreto correspondiente de GitHub.

Cada POST a esa URL dispara un nuevo despliegue usando la imagen/configuración actual del servicio (si el servicio usa imagen desde Docker Hub, asegúrate de que apunte al tag que publica el workflow, p. ej. `latest`).

## Conexión con Docker Hub en Railway

Si el servicio despliega desde **Docker Hub**, tras el `docker push` el hook fuerza un redeploy para que Railway tire la imagen nueva. Si usas **deploy desde GitHub** en Railway, este workflow es complementario (imagen + hook) o puedes desactivar el auto-deploy por repo y dejar solo Docker Hub + hook.

## URL del API en el build del frontend

La variable `VITE_API_URL` está definida en el workflow (URL pública del backend en Railway). Si cambia el dominio, edita `env.VITE_API_URL` en [`.github/workflows/docviz-sesion1.yml`](../../.github/workflows/docviz-sesion1.yml).
