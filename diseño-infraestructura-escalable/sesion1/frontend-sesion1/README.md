# frontend-sesion1 (DocViz SPA)

Aplicación web **React 19** + **Vite** + **TypeScript** para DocViz — Sesión 1: conexión a repositorios, workspace, chat, paneles de soporte y administración de células/tareas.

El **API base** en desarrollo suele proxificarse como **`/api`** (Nginx en Docker) o definirse con **`VITE_API_URL`** / **`VITE_SECURITY_URL`** según `.env.example`.

---

## Requisitos

- **Node.js** (compatible con las versiones indicadas en `package.json`; LTS recomendado)
- **npm**

---

## Configuración

1. Copia **`.env.example`** → **`.env`** en esta carpeta.
2. Ajusta `VITE_API_URL`, `VITE_SECURITY_URL`, etc., según si el backend corre en localhost, Docker o una URL pública.

---

## Desarrollo

Desde **`frontend-sesion1`**:

```bash
npm install
npm run dev
```

Por defecto Vite sirve la SPA en el puerto configurado en la consola (habitualmente **5173** o **3000** según `vite.config.ts`).

Otros comandos:

| Comando | Descripción |
|---------|-------------|
| `npm run build` | Build de producción → carpeta **`dist/`** |
| `npm run preview` | Servir el build localmente |
| `npm run lint` | ESLint |
| `npm run test` | Vitest |

---

## Docker

- **`Dockerfile`** — Imagen **Nginx** con la SPA construida y proxy a `/api` y `/security-api`.
- Uso típico: **`Sesion 1/docker-compose.yml`**, servicio **`frontend`** (perfil **`containerized`**).

Publicación: **`Sesion 1/DOCKERHUB.md`**.

---

## Notas

- Tras **`npm run build`**, los assets llevan hash en el nombre; si ves UI antigua en el navegador, fuerza recarga (**Ctrl+F5**) o revisa cabeceras de caché del servidor (el `nginx.conf` del proyecto evita cachear **`index.html`** sin sentido negativo para hashes nuevos).
