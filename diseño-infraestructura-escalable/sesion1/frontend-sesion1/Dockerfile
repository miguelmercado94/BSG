# syntax=docker/dockerfile:1
# Build estático (Vite) + nginx sirve solo la SPA (sin proxy a "backend": falla en Railway).
FROM node:22-alpine AS build
WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci

COPY . .

# URL base del API en el navegador. En Docker Compose: /api (Nginx reenvía a backend). Sin proxy: http://host:8080/docviz
ARG VITE_API_URL=/api
ENV VITE_API_URL=${VITE_API_URL}
# back-security: /security-api con Nginx → back-security:8081/security-auth; sin proxy: http://host:8081/security-auth
ARG VITE_SECURITY_URL=/security-api
ENV VITE_SECURITY_URL=${VITE_SECURITY_URL}

RUN npm run build

FROM nginx:1.27-alpine
LABEL org.opencontainers.image.title="DocViz Frontend" \
      org.opencontainers.image.description="React + Vite SPA"

RUN apk add --no-cache gettext

COPY --from=build /app/dist /usr/share/nginx/html
COPY docker/default.conf.template /etc/nginx/docviz-default.conf.template
COPY docker/runtime-config.js.template /usr/share/nginx/html/runtime-config.js.template
COPY docker/50-runtime-config.sh /docker-entrypoint.d/50-runtime-config.sh
RUN chmod +x /docker-entrypoint.d/50-runtime-config.sh

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=3s --start-period=15s --retries=3 \
  CMD wget -qO- http://127.0.0.1/ >/dev/null || exit 1
