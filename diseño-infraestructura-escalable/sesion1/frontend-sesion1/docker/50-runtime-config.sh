#!/bin/sh
set -e
# Compose / Railway: URLs absolutas sin barra final. Compat con nombres heredados de build Vite.
export BACKEND_URL="${BACKEND_URL:-${VITE_API_URL:-}}"
export SECURITY_URL="${SECURITY_URL:-${VITE_SECURITY_URL:-}}"
TEMPLATE="/usr/share/nginx/html/runtime-config.js.template"
OUT="/usr/share/nginx/html/runtime-config.js"
if [ ! -f "$TEMPLATE" ]; then
  echo "docviz: falta $TEMPLATE" >&2
  exit 1
fi
envsubst '${BACKEND_URL} ${SECURITY_URL}' <"$TEMPLATE" >"$OUT"