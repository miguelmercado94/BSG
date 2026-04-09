#!/bin/sh
set -e
# Railway / Docker: BACKEND_URL (p. ej. https://tu-api.up.railway.app). Compat: VITE_API_URL.
export BACKEND_URL="${BACKEND_URL:-${VITE_API_URL:-}}"
TEMPLATE="/usr/share/nginx/html/runtime-config.js.template"
OUT="/usr/share/nginx/html/runtime-config.js"
if [ ! -f "$TEMPLATE" ]; then
  echo "docviz: falta $TEMPLATE" >&2
  exit 1
fi
envsubst '${BACKEND_URL}' <"$TEMPLATE" >"$OUT"
