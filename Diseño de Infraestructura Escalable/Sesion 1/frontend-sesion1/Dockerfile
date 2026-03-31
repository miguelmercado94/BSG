# syntax=docker/dockerfile:1
# Build estático (Vite) + nginx sirve solo la SPA (sin proxy a "backend": falla en Railway).
FROM node:22-alpine AS build
WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci

COPY . .

# URL base del API en el navegador (obligatoria). Ej.: http://127.0.0.1:8080 (compose) o https://tu-api.up.railway.app
ARG VITE_API_URL=/api
ENV VITE_API_URL=${VITE_API_URL}

RUN npm run build

FROM nginx:1.27-alpine
LABEL org.opencontainers.image.title="DocViz Frontend" \
      org.opencontainers.image.description="React + Vite SPA"

COPY --from=build /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=3s --start-period=15s --retries=3 \
  CMD wget -qO- http://127.0.0.1/ >/dev/null || exit 1
