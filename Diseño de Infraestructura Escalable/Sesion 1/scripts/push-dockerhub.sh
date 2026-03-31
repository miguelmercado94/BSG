#!/usr/bin/env bash
# Construye y sube las imágenes a Docker Hub. Uso previo: docker login
#
# Uso:
#   chmod +x scripts/push-dockerhub.sh
#   ./scripts/push-dockerhub.sh miguelmercado94
#   ./scripts/push-dockerhub.sh miguelmercado94 latest '!local,develop' '/api'

set -euo pipefail

DOCKER_USER="${1:?Usuario Docker Hub (ej. miguelmercado94)}"
TAG="${2:-latest}"
MAVEN_PROFILES="${3:-local}"
VITE_API_URL="${4:-/api}"

SESSION_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$SESSION_ROOT"

BACKEND_IMAGE="${DOCKER_USER}/docviz-sesion1-backend:${TAG}"
FRONTEND_IMAGE="${DOCKER_USER}/docviz-sesion1-frontend:${TAG}"

echo "==> Backend: ${BACKEND_IMAGE} (MAVEN_PROFILES=${MAVEN_PROFILES})"
docker build \
  --build-arg "MAVEN_PROFILES=${MAVEN_PROFILES}" \
  -t "${BACKEND_IMAGE}" \
  -f backend-sesion1/Dockerfile \
  backend-sesion1

echo "==> Frontend: ${FRONTEND_IMAGE} (VITE_API_URL=${VITE_API_URL})"
docker build \
  --build-arg "VITE_API_URL=${VITE_API_URL}" \
  -t "${FRONTEND_IMAGE}" \
  -f frontend-sesion1/Dockerfile \
  frontend-sesion1

echo "==> docker push ${BACKEND_IMAGE}"
docker push "${BACKEND_IMAGE}"

echo "==> docker push ${FRONTEND_IMAGE}"
docker push "${FRONTEND_IMAGE}"

echo "Listo: ${BACKEND_IMAGE} y ${FRONTEND_IMAGE}"
