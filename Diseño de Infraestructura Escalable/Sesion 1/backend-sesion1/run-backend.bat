@echo off
cd /d "%~dp0"
rem Spring Boot 3.x requiere JDK 17+ (Spring AI / Ollama).
if exist "C:\Program Files\Microsoft\jdk-17.0.18.8-hotspot\bin\java.exe" (
  set "JAVA_HOME=C:\Program Files\Microsoft\jdk-17.0.18.8-hotspot"
  set "PATH=%JAVA_HOME%\bin;%PATH%"
)
rem La clave puede ir en PINECONE_API_KEY o en .pinecone.local.properties (recomendado).
echo Arrancando backend en http://localhost:8080 ...

if exist "target\backend-sesion1-0.1.0-SNAPSHOT.jar" (
  java -jar target\backend-sesion1-0.1.0-SNAPSHOT.jar
) else (
  echo Arrancando con Maven Wrapper (mvnw)...
  call mvnw.cmd -q spring-boot:run
)
pause
