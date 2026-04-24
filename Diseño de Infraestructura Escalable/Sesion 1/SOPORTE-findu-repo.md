# Soporte (caso de uso) — formato para indexar en RAG

Un **soporte** documenta un **problema concreto**, la **solución aplicada**, los **archivos tocados** y las **dificultades** encontradas, para recuperar contexto en RAG o en revisión de código.

---

## Plantilla (copiar y rellenar)

```markdown
## Enunciado
- Problema:
- Alcance:
- Fuera de alcance:

## Solución
1. ...
2. ...

## Clases y archivos
| Archivo | Rol |
|---------|-----|

## Dependencias
- Backend:
- Frontend:
- Infra / env:

## Dificultades
- ...
```

---

## Ejemplo rellenado: cierre de sesión (**logout**) — DocViz + security

**Contexto:** Proyecto de práctica BSG (Sesión 1: `backend-sesion1`, `frontend-sesion1`, `back-security-sesion1`). El micro de seguridad es el mismo patrón que `SECURITY/findu-spring-security` en el repo [findu](https://github.com/miguelmercado94/findu).

### Enunciado

- **Problema:** Hacía falta un **cierre de sesión unificado**: al salir, el usuario no debía seguir viendo su workspace ni datos sensibles en el navegador; en servidor había que **liberar el estado DocViz** (repo conectado, vectores del namespace, carpetas bajo el usuario) y **invalidar los JWT** en el micro de seguridad para que no sigan siendo aceptados donde haya revocación o lista negra.
- **Alcance:** Un flujo disparado desde la UI (“Cerrar sesión”), orquestado en el cliente, con **POST** al backend DocViz y **POST** al API de logout del security, más limpieza de almacenamiento local (tokens / identidad en front).
- **Fuera de alcance:** Cambiar el modelo de usuarios global del producto; no se rediseña login ni registro, solo el **cierre coordinado** entre DocViz y security.

### Solución

1. **Frontend:** Centralizar la lógica en `logoutSession()`: si existe identificador DocViz, llamar a `POST /session/logout` del backend con las cabeceras de sesión habituales; después llamar a `logoutSecurity()` para enviar `accessToken` y `refreshToken` al endpoint `POST /api/v1/auth/logout` del micro de seguridad; finalmente `clearAuthSession()` para borrar estado local aunque falle la revocación remota.
2. **Backend DocViz:** `SessionController` expone `POST /session/logout` sin cuerpo y delega en `SessionLogoutService.logout()`: resolver usuario con `CurrentUser.require()`, si hay sesión con repo conectado y vectorial habilitado llamar a `VectorStore.deleteAllInNamespace` para el namespace del usuario, desconectar `UserRepositoryState` y quitar la entrada de `SessionRegistry`, borrar en disco la carpeta del usuario bajo la raíz DocViz (recursivo), registrando advertencias si fallan vector o filesystem sin abortar todo el cierre.
3. **Micro security:** El cliente envía `LogoutRequest` (access obligatorio, refresh opcional); `AuthController` delega en `JwtManagerImpl.logout`, que persiste la revocación según adaptadores DynamoDB/Redis del proyecto.
4. **UX:** Botones “Cerrar sesión” en `WorkspacePage` y `SessionRailPanel` con estado de carga y mensaje de error si falla el paso al API DocViz; la revocación JWT se trata como **best-effort** para no bloquear la salida del usuario.

### Clases y archivos

| Archivo | Rol |
|---------|-----|
| `frontend-sesion1/src/api/client.ts` | `logoutSession()`, `logoutSecurity()`, `clearAuthSession()` — orquestación y limpieza local. |
| `frontend-sesion1/src/pages/WorkspacePage.tsx` | Acción de logout, `logoutLoading` / `logoutErr`. |
| `frontend-sesion1/src/components/SessionRailPanel.tsx` | Mismo patrón de logout en panel lateral. |
| `backend-sesion1/src/main/java/com/bsg/docviz/web/SessionController.java` | Endpoint `POST /session/logout`. |
| `backend-sesion1/src/main/java/com/bsg/docviz/service/SessionLogoutService.java` | Lógica de vaciado vectorial, registro de sesión y borrado de carpeta de usuario. |
| `back-security-sesion1/.../presentation/controller/AuthController.java` | `POST /api/v1/auth/logout`. |
| `back-security-sesion1/.../application/usecase/impl/JwtManagerImpl.java` | Implementación del caso de uso `logout`. |
| `back-security-sesion1/.../dto/request/LogoutRequest.java` | Contrato del cuerpo JSON del logout en security. |

### Dependencias

- **Backend:** Spring Web (DocViz), `VectorStore` + `VectorProperties`, `SessionRegistry`, `DocvizProperties`, `CurrentUser`; en security — Spring WebFlux, R2DBC PostgreSQL, Redis y DynamoDB opcionales según perfil.
- **Frontend:** `fetch` API; `VITE_API_URL` y URL base del security vía `securityBase()` en `client.ts`.
- **Infra / env:** URLs públicas coherentes entre front, API DocViz y servicio de seguridad (local, Docker o Railway); tokens leídos/escritos con las helpers del propio `client.ts`.

### Dificultades

- **Dos “sesiones” distintas:** La percepción es un solo botón, pero hay estado en **DocViz** (memoria, disco, índice) y **tokens** en otro host; hubo que fijar **orden** (primero limpiar DocViz, luego revocar JWT) y política si uno falla.
- **Fallo del micro security:** Si el security no responde o el token ya expiró, bloquear la UI sería incorrecto; se encapsuló la revocación en try/catch y se limpia la sesión local **siempre**.
- **Vectores y disco asíncronos a fallos:** Red lenta o permisos pueden hacer fallar `deleteAllInNamespace` o el borrado recursivo; se optó por **log de warning** y seguir para no dejar sesión colgada en `SessionRegistry`.
- **Configuración de URLs y CORS:** Errores poco claros cuando `VITE_API_URL` o la base del security no coinciden con el despliegue; hay que validar env en cada entorno.

---

## Notas para indexar en RAG

- Repite en el título o el primer encabezado el **nombre del feature** (p. ej. “logout”).
- Incluye **rutas HTTP y nombres de clase** tal cual en el código.
- Un documento = **un problema**; si mezclas varios, el recuperador diluye el contexto.

---

*Equivalencia findu: el módulo de seguridad del monorepo [findu](https://github.com/miguelmercado94/findu) (`SECURITY/findu-spring-security`) cumple el mismo rol que `back-security-sesion1` en este ejemplo.*
