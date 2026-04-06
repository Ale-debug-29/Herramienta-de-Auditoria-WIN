@echo off
setlocal
title Auditoria

:: --- COMPROBAR PERMISOS DE ADMINISTRADOR ---
net session >nul 2>&1
if %errorLevel% == 0 (
    goto :run_script
) else (
    goto :elevate
)

:elevate
:: Crea un script temporal en VBS para pedir permisos de admin
echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
echo UAC.ShellExecute "%~s0", "", "", "runas", 1 >> "%temp%\getadmin.vbs"
"%temp%\getadmin.vbs"
del "%temp%\getadmin.vbs"
exit /B

:run_script
cls
echo ============================================================
echo      INSTALADOR AUDITORIA (MODO ADMINISTRADOR)
echo ============================================================
echo.

:: --- CONFIGURACION DE URLS ---
:: Asegurate de que estas URLs apunten a tu repositorio RAW
set "URL_INSTALLER=https://raw.githubusercontent.com/Ale-debug-29/Herramienta-de-Auditoria-WIN/refs/heads/main/Instalador.bat"
set "TEMP_PS1=%TEMP%\Instalar-Navaja.ps1"

echo [*] Descargando componentes de instalacion...
powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '%URL_INSTALLER%' -OutFile '%TEMP_PS1%' -UseBasicParsing"

if exist "%TEMP_PS1%" (
    echo [OK] Descarga completada.
    echo [*] Ejecutando configuracion de tareas...
    echo.
    powershell -NoProfile -ExecutionPolicy Bypass -File "%TEMP_PS1%"
    del "%TEMP_PS1%"
) else (
    echo [!] ERROR: No se pudo conectar con GitHub.
    pause
)

exit
