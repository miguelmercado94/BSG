# Ejecutar UNA VEZ en PowerShell (como usuario normal): fija JAVA_HOME de usuario a JDK 21
# y antepone jdk-21\bin al PATH de usuario. Cierra y vuelve a abrir terminales/IDE.

$jdk = if ($env:DOCVIZ_JDK21) { $env:DOCVIZ_JDK21 } else { "C:\Program Files\Java\jdk-21" }
if (-not (Test-Path "$jdk\bin\java.exe")) {
    Write-Error "No se encuentra JDK 21 en '$jdk'."
    exit 1
}

[Environment]::SetEnvironmentVariable("JAVA_HOME", $jdk, "User")

$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
$bin = "$jdk\bin"
if ($userPath -notlike "*$bin*") {
    [Environment]::SetEnvironmentVariable("Path", "$bin;$userPath", "User")
}

Write-Host "Listo. JAVA_HOME (usuario)=$jdk"
Write-Host "Cierra terminales y Cursor/VS Code y vuelve a abrir para que tome efecto."
