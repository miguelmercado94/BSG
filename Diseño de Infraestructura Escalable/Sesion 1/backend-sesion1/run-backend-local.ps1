# Backend Spring Boot en local con JDK 21.
# Si Maven usa JDK 17, este script fuerza JAVA_HOME al 21 (ruta habitual en Windows).
# Antes: detén docviz-backend si quieres el puerto 8080: docker stop docviz-backend
# Uso: .\run-backend-local.ps1

$ErrorActionPreference = "Stop"

$jdk21 = "C:\Program Files\Java\jdk-21"
if (-not (Test-Path "$jdk21\bin\java.exe")) {
    if ($env:JAVA_HOME -and (Test-Path "$env:JAVA_HOME\bin\java.exe")) {
        $jdk21 = $env:JAVA_HOME
        Write-Host "Usando JAVA_HOME existente: $jdk21" -ForegroundColor Yellow
    } else {
        Write-Host "Instala JDK 21 o define JAVA_HOME. Ruta esperada: C:\Program Files\Java\jdk-21" -ForegroundColor Red
        exit 1
    }
}

$env:JAVA_HOME = $jdk21
$env:Path = "$jdk21\bin;$env:Path"

Write-Host "JAVA_HOME=$env:JAVA_HOME" -ForegroundColor Green
# java escribe en stderr: en PowerShell con $ErrorActionPreference=Stop falla; usar cmd evita el error nativo
cmd /c "java -version"

if (-not $env:OLLAMA_BASE_URL) {
    $env:OLLAMA_BASE_URL = "http://127.0.0.1:11434"
}

# S3 LocalStack (panel SOPORTE). Sin LocalStack: $env:DOCVIZ_SUPPORT_ENABLED = "false"
if (-not $env:DOCVIZ_SUPPORT_S3_ENDPOINT) {
    $env:DOCVIZ_SUPPORT_S3_ENDPOINT = "http://127.0.0.1:4566"
}

Set-Location $PSScriptRoot
mvn spring-boot:run
