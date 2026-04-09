# Publicar imágenes en Docker Hub

Para **CI/CD automático** (GitHub Actions → Docker Hub → Railway al merge a `main`), ver [CI-RAILWAY.md](./CI-RAILWAY.md).

## Requisitos

1. Cuenta en [Docker Hub](https://hub.docker.com).
2. Iniciar sesión en la CLI:

   ```bash
   docker login
   ```

3. Ejecutar los comandos desde la carpeta **`Sesion 1`** (donde están `backend-sesion1/` y `frontend-sesion1/`).

Si `docker push` falla con *denied*, *unauthorized* o *context canceled*, ejecuta de nuevo `docker login` y usa `-DockerHubUser` con **tu** ID de Docker Hub (debe coincidir con la cuenta con la que iniciaste sesión).

## Nombres de imagen

Por convención usamos:

| Imagen | Descripción |
|--------|-------------|
| `<usuario>/docviz-sesion1-backend` | API Spring Boot |
| `<usuario>/docviz-sesion1-frontend` | Nginx + SPA Vite |

Sustituye `<usuario>` por tu ID de Docker Hub (ej. `miguelmercado94`).

## Opción A: script (recomendado)

### PowerShell (Windows)

Desde `Sesion 1`:

```powershell
.\scripts\push-dockerhub.ps1 -DockerHubUser TU_USUARIO
```

Gemini (perfil Maven `develop`):

```powershell
.\scripts\push-dockerhub.ps1 -DockerHubUser TU_USUARIO -MavenProfiles '!local,develop'
```

Frontend apuntando a un API en la nube (sustituye la URL):

```powershell
.\scripts\push-dockerhub.ps1 -DockerHubUser TU_USUARIO -MavenProfiles '!local,develop' -ViteApiUrl 'https://tu-api.up.railway.app'
```

**Solo frontend** (sin reconstruir el backend): el build de Vite debe usar la URL **HTTPS pública del API** en Railway, **sin barra final**. Ejemplo del proyecto:

```powershell
.\scripts\push-frontend-dockerhub.ps1 -DockerHubUser TU_USUARIO
```

Por defecto el script usa `https://docviz-sesion1-backend-production.up.railway.app`. Para otra URL:

```powershell
.\scripts\push-frontend-dockerhub.ps1 -DockerHubUser TU_USUARIO -ViteApiUrl 'https://otro-api.up.railway.app'
```

### Bash (Linux / macOS / Git Bash)

```bash
chmod +x scripts/push-dockerhub.sh
./scripts/push-dockerhub.sh TU_USUARIO
./scripts/push-dockerhub.sh TU_USUARIO latest '!local,develop' '/api'
```

## Opción B: comandos manuales

Sustituye `TU_USUARIO` y, si hace falta, el tag `latest`.

**Backend** (Ollama / perfil Maven `local`):

```bash
docker build -t TU_USUARIO/docviz-sesion1-backend:latest -f backend-sesion1/Dockerfile backend-sesion1
docker push TU_USUARIO/docviz-sesion1-backend:latest
```

**Backend** (Gemini):

```bash
docker build --build-arg MAVEN_PROFILES='!local,develop' -t TU_USUARIO/docviz-sesion1-backend:latest -f backend-sesion1/Dockerfile backend-sesion1
docker push TU_USUARIO/docviz-sesion1-backend:latest
```

**Frontend** (proxy local `/api` como en docker-compose):

```bash
docker build --build-arg VITE_API_URL=/api -t TU_USUARIO/docviz-sesion1-frontend:latest -f frontend-sesion1/Dockerfile frontend-sesion1
docker push TU_USUARIO/docviz-sesion1-frontend:latest
```

**Frontend** (producción Railway: el navegador llama al API por CORS; URL sin `/` al final):

```bash
docker build --build-arg VITE_API_URL=https://docviz-sesion1-backend-production.up.railway.app -t TU_USUARIO/docviz-sesion1-frontend:latest -f frontend-sesion1/Dockerfile frontend-sesion1
docker push TU_USUARIO/docviz-sesion1-frontend:latest
```

## Repositorios en Docker Hub

La primera vez que hagas `docker push`, Docker Hub puede crear el repositorio automáticamente (según permisos). También puedes crear antes los repos **docviz-sesion1-backend** y **docviz-sesion1-frontend** como *public* o *private* desde la web.

## Etiquetas adicionales

Para versionar:

```bash
docker tag TU_USUARIO/docviz-sesion1-backend:latest TU_USUARIO/docviz-sesion1-backend:1.0.0
docker push TU_USUARIO/docviz-sesion1-backend:1.0.0
```

## Nota sobre arquitecturas

Las imágenes se construyen para la **arquitectura de la máquina donde ejecutas `docker build`** (p. ej. `linux/amd64` en la mayoría de PCs y en muchos servidores). Si necesitas **multi-arch** (`arm64` + `amd64`), usa `docker buildx` con `--platform`; no está incluido en los scripts por defecto.
