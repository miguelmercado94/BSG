# soporte-rag-mt

Microservicio RAG de soporte — **WebFlux**, **MongoDB**, **PostgreSQL/pgvector**, **Spring AI**, **S3**, **Redis** (opcional).

Arquitectura limpia (nombres en español):

```
com.bsg.soporterag
├── dominio/              # modelos y puertos de salida
├── aplicacion/           # casos de uso, DTOs, servicios
├── infraestructura/      # adaptadores (web, persistencia, S3, cache, IA)
└── configuracion/        # beans Spring, propiedades, perfiles
```

## pgvector — dos fuentes RAG

| Fuente | Enum | Tabla (default) | Origen de datos |
|--------|------|-------------------|-----------------|
| Git | `FuenteRag.GIT` | `soporte_rag_git_chunk` | Código del repo (`repoLabel/ruta`) |
| Soporte | `FuenteRag.SOPORTE` | `soporte_rag_soporte_chunk` | Markdown en S3 (`soporte:clave`) |

Propiedades: `soporte-rag.vector.tabla-git` y `soporte-rag.vector.tabla-soporte`.

El puerto `AlmacenVectorialPort` recibe `FuenteRag` y escribe/lee en la tabla correspondiente.

## Modelo de dominio (Mongo + pgvector)

Diagrama: [`../doc/diagram-soporte-rag-mt-modelo.drawio`](../doc/diagram-soporte-rag-mt-modelo.drawio)

| Decisión | Detalle |
|----------|---------|
| **Célula ↔ Repo N:M** | Colección `celula_repositorio` (`codigoCelula`, `nombreRepo`). Un repo Git se indexa **una vez** en pgvector y puede enlazarse a varias células sin re-embedding. |
| **Repo global** | `RepositorioDocumento.nombreRepo` es único; ya no lleva `codigoCelula` embebido. |
| **Soportes en workarea** | Los `DocumentoSoporte` se guardan bajo `RepositorioDocumento.urlFolderS3Workarea` (bucket `RolBucketS3.WORKAREA`). `urlBucketS3` es la clave relativa a ese prefijo. |
| **Árbol del repo** | Sustituido por `filesPath` y `folderPath` (listas de rutas indexables). |

## S3 — tres buckets (igual que backend-sesion1)

| Rol | Property | Local | Nube (Terraform) |
|-----|----------|-------|------------------|
| Soporte RAG | `bucket-soporte` | `soporte` | `bsg-docviz-soporte-env` |
| Borradores | `bucket-borradores` | `borradores` | `bsg-docviz-borradores-env` |
| Workarea | `bucket-workarea` | `workarea` | `bsg-docviz-workarea-env` |

Un solo cliente S3 (`endpoint` + credenciales); el adaptador elige bucket vía `RolBucketS3`.

## Perfiles

| Perfil | IA | Redis | S3 | Logs |
|--------|----|-------|-----|------|
| `local` | Ollama | **Desactivado** (NoOp) | LocalStack (`endpoint` + path-style) | DEBUG |
| `nube` | OpenAI | ElastiCache | AWS IAM (sin endpoint) | INFO |

```powershell
# Local
$env:SPRING_PROFILES_ACTIVE="local"
mvn spring-boot:run

# Nube (ECS/Fargate)
$env:SPRING_PROFILES_ACTIVE="nube"
$env:OPENAI_API_KEY="sk-..."
$env:REDIS_HOST="..."
mvn spring-boot:run
```

## Dependencias locales sugeridas

- PostgreSQL 16 + extensión `vector`
- MongoDB
- Ollama (`ollama pull llama3.2` + `nomic-embed-text`)
- LocalStack en `:4566` (buckets `soporte`, `borradores`, `workarea`)

## Endpoints

- `GET /actuator/health` — probes
- `GET /api/v1/infraestructura/salud` — resumen de perfil e infra conectada

## Variables principales

Ver `.env.example` y `application-local.properties.example`.

Puerto por defecto: **8090**.
