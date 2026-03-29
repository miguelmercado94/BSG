@echo off
cd /d "%~dp0"
set TARGET=context-masters\miguelmt103\remix-compute
if exist "%TARGET%" (
  rmdir /s /q "%TARGET%"
  echo Clon 'remix-compute' eliminado. Reconecta desde la app para clonar de nuevo.
) else (
  echo No se encontro "%TARGET%". Nada que borrar.
)
pause
