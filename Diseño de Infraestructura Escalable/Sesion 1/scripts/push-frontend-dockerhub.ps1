# Construye y sube solo la imagen del frontend (Vite + Nginx) a Docker Hub.
# Uso previo: docker login
# Desde la carpeta Sesion 1: .\scripts\push-frontend-dockerhub.ps1 -DockerHubUser mmercado94
#
# URL por defecto: API público de Railway (Sesión 1). Sin barra final.

param(
    [Parameter(Mandatory = $true)]
    [string] $DockerHubUser,

    [string] $Tag = "latest",

    [string] $ViteApiUrl = "https://docviz-sesion1-backend-production.up.railway.app"
)

$ErrorActionPreference = "Stop"
$SessionRoot = Split-Path -Parent $PSScriptRoot
Set-Location $SessionRoot

$frontendImage = "${DockerHubUser}/docviz-sesion1-frontend:${Tag}"

Write-Host "==> Frontend: $frontendImage (VITE_API_URL=$ViteApiUrl)"
docker build `
    --build-arg "VITE_API_URL=$ViteApiUrl" `
    -t $frontendImage `
    -f "frontend-sesion1/Dockerfile" `
    "frontend-sesion1"

Write-Host "==> docker push $frontendImage"
docker push $frontendImage

Write-Host "Listo: $frontendImage"
