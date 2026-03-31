# Construye y sube las imágenes DocViz Sesión 1 a Docker Hub.
# Uso previo: docker login
#
# Ejemplos:
#   .\scripts\push-dockerhub.ps1 -DockerHubUser miguelmercado94
#   .\scripts\push-dockerhub.ps1 -DockerHubUser miguelmercado94 -Tag "1.0.0" -MavenProfiles "!local,develop"
#   .\scripts\push-dockerhub.ps1 -DockerHubUser miguelmercado94 -ViteApiUrl "https://tu-api.up.railway.app"

param(
    [Parameter(Mandatory = $true)]
    [string] $DockerHubUser,

    [string] $Tag = "latest",

    # Perfil Maven del backend: "local" (Ollama) o "!local,develop" (Gemini)
    [string] $MavenProfiles = "local",

    # Build del frontend: en local suele ser /api (nginx); en nube, URL pública del API
    [string] $ViteApiUrl = "/api"
)

$ErrorActionPreference = "Stop"
# Carpeta "Sesion 1" (padre de scripts/)
$SessionRoot = Split-Path -Parent $PSScriptRoot
Set-Location $SessionRoot

$backendImage = "${DockerHubUser}/docviz-sesion1-backend:${Tag}"
$frontendImage = "${DockerHubUser}/docviz-sesion1-frontend:${Tag}"

Write-Host "==> Backend: $backendImage (MAVEN_PROFILES=$MavenProfiles)"
docker build `
    --build-arg "MAVEN_PROFILES=$MavenProfiles" `
    -t $backendImage `
    -f "backend-sesion1/Dockerfile" `
    "backend-sesion1"

Write-Host "==> Frontend: $frontendImage (VITE_API_URL=$ViteApiUrl)"
docker build `
    --build-arg "VITE_API_URL=$ViteApiUrl" `
    -t $frontendImage `
    -f "frontend-sesion1/Dockerfile" `
    "frontend-sesion1"

Write-Host "==> docker push $backendImage"
docker push $backendImage

Write-Host "==> docker push $frontendImage"
docker push $frontendImage

Write-Host "Listo: $backendImage y $frontendImage"
