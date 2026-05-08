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
NGINX_TMPL="/etc/nginx/docviz-default.conf.template"
if [ -f "$NGINX_TMPL" ]; then
  envsubst '$DOCVIZ_UPSTREAM $SECURITY_UPSTREAM $NGINX_RESOLVER' <"$NGINX_TMPL" >/etc/nginx/conf.d/default.conf
fi
TEMPLATE="/usr/share/nginx/html/runtime-config.js.template"
OUT="/usr/share/nginx/html/runtime-config.js"
if [ ! -f "$TEMPLATE" ]; then
  echo "docviz: falta $TEMPLATE" >&2
  exit 1
fi
envsubst '${BACKEND_URL} ${SECURITY_URL}' <"$TEMPLATE" >"$OUT"