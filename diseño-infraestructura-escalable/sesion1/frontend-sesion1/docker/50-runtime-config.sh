#!/bin/sh
set -e
# Compose / Railway: URLs absolutas sin barra final. Compat con nombres heredados de build Vite.
export BACKEND_URL="${BACKEND_URL:-${VITE_API_URL:-}}"
export SECURITY_URL="${SECURITY_URL:-${VITE_SECURITY_URL:-}}"
# Proxy interno Nginx → backend / security (Compose: nombres de servicio; ECS: Cloud Map *.bsg.internal).
export DOCVIZ_UPSTREAM="${DOCVIZ_UPSTREAM:-http://backend:8080}"
export SECURITY_UPSTREAM="${SECURITY_UPSTREAM:-http://back-security:8081}"
# Resolver DNS: Docker embebido | VPC AWS (Fargate). Ver default.conf.template (resolver + proxy_pass variable).
export NGINX_RESOLVER="${NGINX_RESOLVER:-127.0.0.11}"

# proxy_pass con URL completa en una variable puede dar 500 en Nginx; separar host y puerto:
# proxy_pass http://$host:puerto (solo el nombre en variable → DNS Cloud Map por petición).
DOCVIZ_PROXY_HOST=$(printf '%s\n' "$DOCVIZ_UPSTREAM" | sed -e 's|^[^/]*//||' -e 's|:.*||')
DOCVIZ_PROXY_PORT=$(printf '%s\n' "$DOCVIZ_UPSTREAM" | sed -n 's|.*:\([0-9][0-9]*\)$|\1|p')
SECURITY_PROXY_HOST=$(printf '%s\n' "$SECURITY_UPSTREAM" | sed -e 's|^[^/]*//||' -e 's|:.*||')
SECURITY_PROXY_PORT=$(printf '%s\n' "$SECURITY_UPSTREAM" | sed -n 's|.*:\([0-9][0-9]*\)$|\1|p')
[ -z "$DOCVIZ_PROXY_PORT" ] && DOCVIZ_PROXY_PORT=8080
[ -z "$SECURITY_PROXY_PORT" ] && SECURITY_PROXY_PORT=8081
export DOCVIZ_PROXY_HOST DOCVIZ_PROXY_PORT SECURITY_PROXY_HOST SECURITY_PROXY_PORT

NGINX_TMPL="/etc/nginx/docviz-default.conf.template"
if [ -f "$NGINX_TMPL" ]; then
  envsubst '$DOCVIZ_PROXY_HOST $DOCVIZ_PROXY_PORT $SECURITY_PROXY_HOST $SECURITY_PROXY_PORT $NGINX_RESOLVER' <"$NGINX_TMPL" >/etc/nginx/conf.d/default.conf
fi
TEMPLATE="/usr/share/nginx/html/runtime-config.js.template"
OUT="/usr/share/nginx/html/runtime-config.js"
if [ ! -f "$TEMPLATE" ]; then
  echo "docviz: falta $TEMPLATE" >&2
  exit 1
fi
envsubst '${BACKEND_URL} ${SECURITY_URL}' <"$TEMPLATE" >"$OUT"