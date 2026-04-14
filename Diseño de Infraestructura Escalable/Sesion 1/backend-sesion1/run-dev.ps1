# Arranca Spring Boot con JDK 21 (Maven usa JAVA_HOME; si apunta a 17, la compilacion falla).
# Opcional: $env:DOCVIZ_JDK21 = "C:\ruta\a\jdk-21"

$ErrorActionPreference = "Stop"
$jdk = if ($env:DOCVIZ_JDK21) { $env:DOCVIZ_JDK21 } else { "C:\Program Files\Java\jdk-21" }
if (-not (Test-Path "$jdk\bin\java.exe")) {
    Write-Error "No se encuentra JDK 21 en '$jdk'. Instala JDK 21 o define DOCVIZ_JDK21."
    exit 1
}
$env:JAVA_HOME = $jdk
$env:Path = "$jdk\bin;" + $env:Path
Write-Host "JAVA_HOME=$env:JAVA_HOME"
& "$PSScriptRoot\mvnw.cmd" spring-boot:run @args
