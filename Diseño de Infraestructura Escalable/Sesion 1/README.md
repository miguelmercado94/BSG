# Sesión 1 — DocViz / BSG

Monorepo de **Diseño de Infraestructura Escalable**: backend DocViz, frontend SPA, servicio de seguridad JWT y orquestación con **`docker-compose.yml`**.

## Proyectos

| Carpeta | Descripción | README |
|---------|-------------|--------|
| **`backend-sesion1`** | API Spring Boot DocViz (Git, RAG, S3 work area, pgvector, …) | [backend-sesion1/README.md](./backend-sesion1/README.md) |
| **`frontend-sesion1`** | SPA React + Vite | [frontend-sesion1/README.md](./frontend-sesion1/README.md) |
| **`back-security-sesion1`** | Autenticación WebFlux + JWT + R2DBC | [back-security-sesion1/README.md](./back-security-sesion1/README.md) |

## Infraestructura local

Desde **esta carpeta** (`Sesion 1`):

```bash
docker compose up -d
```

Backend + frontend en contenedores (perfil **`containerized`**):

```bash
docker compose --profile containerized up -d --build
```

Variables de entorno: **`.env`** (plantilla en `.env.example` si existe).

## Docker Hub

Imágenes y comandos `docker build` / `docker push`: **[DOCKERHUB.md](./DOCKERHUB.md)**.

## Otros documentos

- **`CI-RAILWAY.md`** — CI/CD / Railway (si está en el repo).
- **`ENTREGABLE.md`** — Entregables académicos (si aplica).
