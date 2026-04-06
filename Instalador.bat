@echo off
setlocal
title Instalador Navaja Suiza - Forzar Administrador

:: --- COMPROBAR PERMISOS DE ADMINISTRADOR ---
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo.
    echo  [*] Solicitando permisos de administrador...
    echo.
    powershell -Command "Start-Process -FilePath '%0' -Verb RunAs"
    exit /b
)

:run_script
cls
echo ============================================================
echo      INSTALADOR NAVAJA SUIZA (MODO ADMINISTRADOR)
echo ============================================================
echo.

:: --- CONFIGURACION DE URLS ---
:: Asegurate de que estas URLs apunten a tu repositorio RAW
set "URL_INSTALLER=https://raw.githubusercontent.com/Ale-debug-29/Herramienta-de-Auditoria-WIN/refs/heads/main/Auditoria.ps1"
set "TEMP_PS1=%TEMP%\Instalar-Navaja.ps1"

echo [*] Descargando componentes de instalacion...
:: Intentamos la descarga forzando TLS 1.2
powershell -NoProfile -ExecutionPolicy Bypass -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; try { Invoke-WebRequest -Uri '%URL_INSTALLER%' -OutFile '%TEMP_PS1%' -UseBasicParsing -ErrorAction Stop; Write-Host ' [OK] Descarga completada.' -ForegroundColor Green } catch { Write-Host ' [!] ERROR en descarga: ' + $_.Exception.Message -ForegroundColor Red; exit 1 }"

if %errorLevel% neq 0 (
    echo.
    echo  [!] Hubo un problema al descargar el archivo desde GitHub.
    echo      Verifica tu conexion o que la URL sea correcta.
    echo.
    pause
    exit /b
)

if exist "%TEMP_PS1%" (
    echo [*] Ejecutando configuracion de tareas...
    echo.
    :: Ejecutamos el PS1 ignorando las restricciones de politica locales
    powershell -NoProfile -ExecutionPolicy Bypass -File "%TEMP_PS1%"
    
    echo.
    echo [*] Limpiando archivos temporales...
    del "%TEMP_PS1%" /f /q
    echo [OK] Proceso finalizado.
    pause
) else (
    echo [!] ERROR: El archivo temporal no se encontro tras la descarga.
    pause
)

exit
