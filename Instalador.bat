@echo off
:: Comprobar si el script se ejecuta como administrador
net session >nul 2>&1
if %errorLevel% == 0 (
    goto :admin
) else (
    echo.
    echo  [!] ERROR: Por favor, ejecuta este archivo como ADMINISTRADOR.
    echo.
    pause
    exit /b
)

:admin
title Instalador Navaja Suiza
color 0b
cls
echo ============================================================
echo      DESCARGANDO NAVAJA SUIZA DESDE GITHUB...
echo ============================================================
echo.

:: --- CONFIGURACION ---
:: SUSTITUYE LA SIGUIENTE URL POR TU URL "RAW" DE GITHUB
set "URL_GITHUB=https://raw.githubusercontent.com/Ale-debug-29/Limpieza-semanal/main/NavajaSuiza_Menu.ps1"
set "RUTA_DESTINO=%TEMP%\NavajaSuiza_Menu.ps1"

:: Descargar el archivo usando PowerShell
powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '%URL_GITHUB%' -OutFile '%RUTA_DESTINO%' -UseBasicParsing"

if exist "%RUTA_DESTINO%" (
    echo  [OK] Archivo descargado correctamente.
    echo  [*] Iniciando herramienta...
    timeout /t 2 >nul
    
    :: Ejecutar el script descargado
    powershell -NoProfile -ExecutionPolicy Bypass -File "%RUTA_DESTINO%"
) else (
    echo  [!] ERROR: No se pudo descargar el archivo. 
    echo      Comprueba la conexion a internet o la URL de GitHub.
    pause
)

:: Limpiar al salir (opcional)
del "%RUTA_DESTINO%" >nul 2>&1
exit