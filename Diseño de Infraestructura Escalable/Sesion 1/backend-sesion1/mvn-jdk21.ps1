# Ejecuta mvnw.cmd con JAVA_HOME en JDK 21. Ejemplos:
#   .\mvn-jdk21.ps1 -q compile -DskipTests
#   .\mvn-jdk21.ps1 spring-boot:run
# (arranque local con Ollama/S3: ver run-backend-local.ps1)

$ErrorActionPreference = "Stop"
$jdk = if ($env:DOCVIZ_JDK21) { $env:DOCVIZ_JDK21 } else { "C:\Program Files\Java\jdk-21" }
if (-not (Test-Path "$jdk\bin\java.exe")) {
    Write-Error "No se encuentra JDK 21 en '$jdk'. Define DOCVIZ_JDK21."
    exit 1
}
$env:JAVA_HOME = $jdk
$env:Path = "$jdk\bin;" + $env:Path
& "$PSScriptRoot\mvnw.cmd" @args
