# ============================================================
# SUITE DE AUDITORÍA Y SEGURIDAD AVANZADA
# Versión: 2.0
# ============================================================

# Forzar a la consola a usar codificación UTF-8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$ErrorActionPreference = "SilentlyContinue"
$DesktopPath = [System.IO.Path]::Combine($env:USERPROFILE, "Desktop")

# Función para limpiar la pantalla y mostrar el encabezado
function Show-Header {
    Clear-Host
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "             MODULO DE AUDITORIA Y SEGURIDAD                " -ForegroundColor White -BackgroundColor DarkBlue
    Write-Host "============================================================" -ForegroundColor Cyan
}

# --- 1. AUDITORÍA DE SEGURIDAD (USUARIOS) ---
function Run-SecurityAudit {
    $file = "$DesktopPath\Auditoria_Usuarios_$($env:COMPUTERNAME).txt"
    $report = @("--- REPORTE DE USUARIOS Y PRIVILEGIOS - $(Get-Date) ---`n")
    Write-Host "`n[*] Analizando Usuarios y Privilegios..." -ForegroundColor Yellow
    
    $admins = Get-LocalGroupMember -Group "Administradores"
    $report += "[ADMINISTRADORES]"
    foreach ($admin in $admins) { $report += "- $($admin.Name) ($($admin.ObjectClass))" }
    
    $report += "`n[USUARIOS INACTIVOS (+90 DIAS)]"
    $limit = (Get-Date).AddDays(-90)
    Get-LocalUser | Where-Object { $_.LastLogon -lt $limit -and $_.LastLogon -ne $null } | ForEach-Object { $report += "- $($_.Name) (Visto: $($_.LastLogon))" }
    
    $report | Out-File -FilePath $file -Encoding UTF8
    Write-Host "[OK] Reporte generado: $file" -ForegroundColor Green
    Pause
}

# --- 2. AUDITORÍA DE RED (PUERTOS ABIERTOS) ---
function Run-NetworkAudit {
    Show-Header
    Write-Host "`n[*] Puertos en ESCUCHA y procesos asociados:" -ForegroundColor Yellow
    Write-Host "PUERTO | PROCESO | PID" -ForegroundColor Gray
    Get-NetTCPConnection -State Listen | ForEach-Object {
        $p = Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue
        Write-Host ">> $($_.LocalPort) | $($p.Name) | $($_.OwningProcess)" -ForegroundColor White
    }
    Pause
}

# --- 3. AUDITORÍA DE TAREAS PROGRAMADAS (PERSISTENCIA) ---
function Run-TaskAudit {
    Show-Header
    Write-Host "`n[*] Buscando Tareas Programadas sospechosas (Scripts)..." -ForegroundColor Yellow
    Get-ScheduledTask | Where-Object { $_.Actions.Execute -match "powershell|cmd|cscript|wscript|\.bat|\.ps1" } | ForEach-Object {
        Write-Host ">> Tarea: $($_.TaskName) | Ruta: $($_.TaskPath)" -ForegroundColor White
        Write-Host "   Ejecuta: $($_.Actions.Execute) $($_.Actions.Arguments)" -ForegroundColor Gray
    }
    Pause
}

# --- 4. AUDITORÍA DE RECURSOS COMPARTIDOS (SMB) ---
function Run-SMBAudit {
    Show-Header
    Write-Host "`n[*] Carpetas compartidas en este equipo:" -ForegroundColor Yellow
    Get-SmbShare | Where-Object { $_.Name -notmatch "\$" } | ForEach-Object {
        Write-Host ">> Nombre: $($_.Name) | Ruta: $($_.Path)" -ForegroundColor White
        $acl = Get-SmbShareAccess -Name $_.Name
        foreach ($a in $acl) { Write-Host "   Acceso: $($a.AccountName) -> $($a.AccessControlType) ($($a.AccessRight))" -ForegroundColor Gray }
    }
    Pause
}

# --- 5. ESTADO DE CIFRADO (BITLOCKER) ---
function Run-BitLockerAudit {
    Show-Header
    Write-Host "`n[*] Estado de cifrado de unidades:" -ForegroundColor Yellow
    $bl = Get-BitLockerVolume
    foreach ($vol in $bl) {
        $color = if ($vol.VolumeStatus -eq "FullyEncrypted") { "Green" } else { "Red" }
        Write-Host ">> Unidad: $($vol.MountPoint) | Estado: $($vol.VolumeStatus) | Cifrado: $($vol.EncryptionMethod)" -ForegroundColor $color
    }
    Pause
}

# --- 6. INVENTARIO DE HARDWARE DETALLADO ---
function Run-HardwareInventory {
    $file = "$DesktopPath\Inventario_Hardware_$($env:COMPUTERNAME).txt"
    Write-Host "`n[*] Generando Inventario detallado..." -ForegroundColor Yellow
    $cpu = Get-CimInstance Win32_Processor
    $board = Get-CimInstance Win32_BaseBoard
    $gpu = Get-CimInstance Win32_VideoController
    $ram = Get-CimInstance Win32_PhysicalMemory
    
    $report = @"
--- INVENTARIO TECNICO ---
PLACA: $($board.Manufacturer) $($board.Product)
CPU: $($cpu.Name)
GPU: $($gpu.Name) (VRAM: $([math]::round($gpu.AdapterRAM / 1MB, 2)) MB)
RAM TOTAL: $([math]::round(($ram | Measure-Object Capacity -Sum).Sum / 1GB, 2)) GB
"@
    $report | Out-File -FilePath $file -Encoding UTF8
    Write-Host "[OK] Guardado en: $file" -ForegroundColor Green
    Pause
}

# --- 7. LIMPIEZA DE TEMPORALES DE TODOS LOS USUARIOS (NUEVO) ---
function Run-UserTempCleanup {
    Show-Header
    Write-Host "`n[*] Iniciando limpieza de temporales de TODOS los usuarios..." -ForegroundColor Yellow
    $userProfiles = Get-ChildItem "C:\Users" -Directory
    
    foreach ($profile in $userProfiles) {
        $tempPath = Join-Path $profile.FullName "AppData\Local\Temp"
        if (Test-Path $tempPath) {
            Write-Host ">> Limpiando temporales de: $($profile.Name)" -ForegroundColor Gray
            Get-ChildItem -Path $tempPath -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
    
    # También limpiar el temporal del sistema
    Write-Host ">> Limpiando carpeta Temp del Sistema..." -ForegroundColor Gray
    Get-ChildItem -Path "C:\Windows\Temp" -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    
    Write-Host "`n[OK] Limpieza de archivos temporales finalizada." -ForegroundColor Green
    Pause
}

# --- 8. MANTENIMIENTO: LIMPIEZA DE LOGS Y SISTEMA ---
function Run-MaintenanceMenu {
    Show-Header
    Write-Host " 1. Limpiar Logs antiguos (+30 dias)"
    Write-Host " 2. Limpieza Profunda (WinSXS y Visores)"
    Write-Host " 3. Volver"
    $mOp = Read-Host "`nSeleccione mantenimiento"
    
    if ($mOp -eq "1") {
        $limitDate = (Get-Date).AddDays(-30)
        Get-ChildItem -Path "C:\Windows\Logs", "C:\Windows\Temp" -Recurse -Include *.log, *.txt | Where-Object { $_.LastWriteTime -lt $limitDate } | Remove-Item -Force
        Write-Host "[OK] Logs borrados." -ForegroundColor Green ; Pause
    }
    elseif ($mOp -eq "2") {
        Write-Host "[*] Ejecutando DISM..." -ForegroundColor Gray
        Dism.exe /online /Cleanup-Image /StartComponentCleanup
        Get-WinEvent -ListLog * | ForEach-Object { [System.Diagnostics.Eventing.Reader.EventLogSession]::GlobalSession.ClearLog($_.LogName) }
        Write-Host "[OK] Limpieza profunda finalizada." -ForegroundColor Green ; Pause
    }
}

# --- BUCLE DEL MENÚ PRINCIPAL ---
do {
    Show-Header
    Write-Host " [SEGURIDAD Y AUDITORIA]" -ForegroundColor DarkCyan
    Write-Host " 1. Auditoria de Usuarios e Inactividad"
    Write-Host " 2. Escaneo de Puertos y Servicios (Red)"
    Write-Host " 3. Analisis de Tareas Programadas (Persistencia)"
    Write-Host " 4. Auditoria de Carpetas Compartidas (SMB)"
    Write-Host " 5. Verificacion de Cifrado (BitLocker)"
    Write-Host "`n [SISTEMA Y MANTENIMIENTO]" -ForegroundColor DarkCyan
    Write-Host " 6. Inventario de Hardware (Archivo TXT)"
    Write-Host " 7. Borrar Temporales (TODOS los usuarios)"
    Write-Host " 8. Menu de Limpieza (Logs y Sistema)"
    Write-Host " 9. Salir"
    Write-Host "------------------------------------------------------------"
    $choice = Read-Host "Seleccione una opcion"

    switch ($choice) {
        "1" { Run-SecurityAudit }
        "2" { Run-NetworkAudit }
        "3" { Run-TaskAudit }
        "4" { Run-SMBAudit }
        "5" { Run-BitLockerAudit }
        "6" { Run-HardwareInventory }
        "7" { Run-UserTempCleanup }
        "8" { Run-MaintenanceMenu }
        "9" { break }
    }
} while ($choice -ne "9")