@echo off
REM Maven usa JAVA_HOME; fuerza JDK 21 para este proceso.
set "JDK21=C:\Program Files\Java\jdk-21"
if defined DOCVIZ_JDK21 set "JDK21=%DOCVIZ_JDK21%"
if not exist "%JDK21%\bin\java.exe" (
  echo No se encuentra JDK 21 en "%JDK21%". Define DOCVIZ_JDK21 o instala JDK 21.
  exit /b 1
)
set "JAVA_HOME=%JDK21%"
set "PATH=%JDK21%\bin;%PATH%"
echo JAVA_HOME=%JAVA_HOME%
cd /d "%~dp0"
call mvnw.cmd spring-boot:run %*
