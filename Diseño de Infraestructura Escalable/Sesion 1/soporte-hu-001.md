# Soporte — HU-001 · Revocación de JWT en logout (back-security)

**Historia de usuario (referencia):** Como sistema de autenticación, quiero que al cerrar sesión los tokens queden revocados de forma **consistente** entre persistencia y caché, para que ningún cliente reutilice un access o refresh válido tras el logout.

---

## Enunciado

- **Problema:** Tras exponer `POST /api/v1/auth/logout`, en entornos con **Redis** y **DynamoDB** activos aparecían ventanas inconsistentes: si solo se actualizaba la caché rápida, un reinicio o otro nodo podía seguir aceptando tokens; si el orden de escritura era incorrecto, un fallo intermedio dejaba el estado difícil de razonar en soporte.
- **Alcance:** Micro **`back-security-sesion1`** (Spring WebFlux): flujo de **logout** con cuerpo `LogoutRequest` (access obligatorio, refresh opcional), revocación persistida y reflejo en caché opcional, sin cambiar el contrato público del login.
- **Fuera de alcance:** Cambiar el algoritmo de firma JWT, el modelo de clientes en frontend ni el despliegue de DocViz; solo la **lógica de revocación** y su orden entre almacenes.

---

## Flujo

1. El **cliente HTTP** envía `POST /api/v1/auth/logout` con JSON `{ "accessToken": "...", "refreshToken": "..." | null }` y cabeceras requeridas por la API (p. ej. algoritmo JWT acordado).
2. **`AuthController`** valida el body y delega en el caso de uso **`JwtManager`** (`logout`).
3. **`JwtManagerImpl`** resuelve la sesión y llama a **`JwtTokenRevocationService.markSessionUnavailable`**, pasando access y refresh opcional.
4. **`JwtTokenRevocationService`** calcula TTL hasta la expiración del token (o el máximo entre access y refresh si el refresh es válido), escribe primero en **DynamoDB** vía **`RevokedTokenRepositoryPort`**, y **después** en **Redis** vía **`TokenRevocationCachePort.putRevokedSession`** con la misma semántica (`available = false`). Un fallo en Redis **no** deshace la revocación en Dynamo.
5. Las comprobaciones posteriores (`isRevoked`) consultan **Redis primero** y, si hace falta, **Dynamo**, alineado con “caché rápida + fuente de verdad persistente”.

---

## Solución

1. **Contrato de entrada:** `LogoutRequest` con `accessToken` obligatorio y `refreshToken` nullable para revocar también el refresh cuando el cliente lo envía.
2. **Caso de uso:** `JwtManagerImpl.logout` valida tokens y delega en `JwtTokenRevocationService` para marcar la sesión como no disponible hasta el fin de vida útil del token.
3. **Orden de escritura:** Persistencia **Dynamo primero**, luego **Redis**, documentado explícitamente para que el logout sea recuperable aunque falle la caché.
4. **Puertos hexagonales:** `RevokedTokenRepositoryPort` (Dynamo) y `TokenRevocationCachePort` (Redis / no-op) mantienen el dominio desacoplado de la infraestructura concreta.

---

## Clases y archivos

| Archivo | Rol |
|---------|-----|
| `back-security-sesion1/.../presentation/controller/AuthController.java` | Expone `POST /api/v1/auth/logout` y delega en `JwtManager`. |
| `back-security-sesion1/.../application/usecase/JwtManager.java` | Contrato del caso de uso (login, refresh, logout). |
| `back-security-sesion1/.../application/usecase/impl/JwtManagerImpl.java` | Implementación de `logout` y coordinación con revocación. |
| `back-security-sesion1/.../dto/request/LogoutRequest.java` | DTO del body del logout. |
| `back-security-sesion1/.../dto/response/AuthToken.java` | Respuesta unificada; variante “logged out” sin reenviar secretos. |
| `back-security-sesion1/.../application/service/JwtTokenRevocationService.java` | **`markSessionUnavailable`**: orden Dynamo → Redis; `isRevoked` Redis → Dynamo. |
| `back-security-sesion1/.../application/port/output/persistence/RevokedTokenRepositoryPort.java` | Puerto de persistencia de sesiones revocadas. |
| `back-security-sesion1/.../application/port/output/cache/TokenRevocationCachePort.java` | Puerto de caché de revocación. |
| Adaptadores en `.../infrastructure/adapter` (Redis, DynamoDB) | Implementaciones concretas de los puertos anteriores. |

---

## Dependencias

- **Backend:** Spring Boot WebFlux, Spring Security reactivo, R2DBC PostgreSQL (usuarios/sesiones según diseño), clientes **AWS SDK async** para DynamoDB y **Spring Data Redis** reactivo cuando los flags `bsg.security.*` activan esos adaptadores.
- **Frontend:** No es objeto de esta HU; cualquier cliente que llame al logout debe enviar el body esperado y cabeceras del API.
- **Infra / env:** Perfiles `qa` / `pdn` con Redis y Dynamo alcanzables; variables tipo `BSG_SECURITY_AWS_DYNAMODB_*`, endpoint LocalStack en local, y TTL alineado con expiración JWT.

---

## Dificultades

- **Dos almacenes con roles distintos:** Había que dejar claro que Dynamo es la **verdad persistente** y Redis la **aceleración**; por eso en logout se escribe primero en Dynamo y el fallo de Redis no revierte el cierre de sesión.
- **TTL y refresh opcional:** Si el refresh no viene o no es válido, el TTL se basa en el access; si viene un refresh válido, se usa el máximo entre ambos para mantener la revocación coherente hasta que expire el último token relevante.
- **Tests reactivos:** `JwtManagerImpl` y controladores usan `Mono`/`Flux`; los tests con `StepVerifier` obligan a mockear bien los puertos para no flaky tests en logout.

---

*Documento de ejemplo para RAG · HU-001 · Solo backend security (`back-security-sesion1`).*
