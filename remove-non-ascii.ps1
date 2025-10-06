# Script para eliminar caracteres no-ASCII de archivos
# Elimina emojis, caracteres especiales, y todo lo que no sea ASCII puro (0-127)
#
# USO:
#   .\remove-non-ascii.ps1 archivo.txt
#   .\remove-non-ascii.ps1 C:\ruta\completa\archivo.txt
#   .\remove-non-ascii.ps1 *.txt

param (
    [Parameter(Mandatory=$true, Position=0)]
    [string]$archivosAProcesar,
    
    [Parameter(Mandatory=$false)]
    [switch]$sinBackup,
    
    [Parameter(Mandatory=$false)]
    [switch]$verbose
)

$ErrorActionPreference = "Stop"

# =====================================================================
# CONFIGURACION DESDE PARAMETROS
# =====================================================================

$crearBackup = -not $sinBackup
$mostrarCaracteresEliminados = $verbose

# =====================================================================
# FUNCIONES
# =====================================================================

function Limpiar-ASCII {
    param (
        [string]$rutaArchivo,
        [bool]$backup = $true,
        [bool]$verbose = $false
    )

    try {
        Write-Host "`nProcesando: $rutaArchivo" -ForegroundColor Cyan

        # Verificar que el archivo existe
        if (!(Test-Path $rutaArchivo)) {
            throw "El archivo no existe: $rutaArchivo"
        }

        # Leer el contenido del archivo
        $contenidoOriginal = Get-Content -Path $rutaArchivo -Raw -Encoding UTF8

        if ([string]::IsNullOrEmpty($contenidoOriginal)) {
            Write-Host "  [!] El archivo esta vacio, se omite." -ForegroundColor Yellow
            return
        }

        # Crear backup si esta habilitado
        if ($backup) {
            $backupPath = "$rutaArchivo.backup"
            Copy-Item -Path $rutaArchivo -Destination $backupPath -Force
            Write-Host "  [OK] Backup creado: $backupPath" -ForegroundColor Gray
        }

        # Estadisticas
        $caracteresOriginales = $contenidoOriginal.Length
        $caracteresNoASCII = 0
        $caracteresEliminados = @()

        # Filtrar caracteres ASCII (0-127)
        $contenidoLimpio = ""
        foreach ($char in $contenidoOriginal.ToCharArray()) {
            $valorASCII = [int]$char
            
            if ($valorASCII -le 127) {
                # Es ASCII valido, lo mantenemos
                $contenidoLimpio += $char
            } else {
                # No es ASCII, lo eliminamos
                $caracteresNoASCII++
                
                if ($verbose) {
                    $caracteresEliminados += "[$char] (codigo: $valorASCII)"
                }
            }
        }

        # Guardar el contenido limpio
        Set-Content -Path $rutaArchivo -Value $contenidoLimpio -Encoding ASCII -NoNewline

        # Mostrar resultados
        $caracteresFinal = $contenidoLimpio.Length
        $porcentajeEliminado = if ($caracteresOriginales -gt 0) { 
            [math]::Round(($caracteresNoASCII / $caracteresOriginales) * 100, 2) 
        } else { 
            0 
        }

        Write-Host "  [STATS] Estadisticas:" -ForegroundColor Green
        Write-Host "     - Caracteres originales: $caracteresOriginales"
        Write-Host "     - Caracteres no-ASCII eliminados: $caracteresNoASCII ($porcentajeEliminado%)"
        Write-Host "     - Caracteres finales: $caracteresFinal"

        # Mostrar caracteres eliminados si esta en modo verbose
        if ($verbose -and $caracteresNoASCII -gt 0) {
            Write-Host "`n  [DEBUG] Caracteres eliminados:" -ForegroundColor Yellow
            $caracteresEliminados | Select-Object -First 20 | ForEach-Object {
                Write-Host "     $_" -ForegroundColor DarkGray
            }
            if ($caracteresNoASCII -gt 20) {
                Write-Host "     ... y $($caracteresNoASCII - 20) mas" -ForegroundColor DarkGray
            }
        }

        Write-Host "  [OK] Archivo limpiado exitosamente`n" -ForegroundColor Green

    } catch {
        Write-Host "`n  [ERROR] Error al procesar archivo" -ForegroundColor Red
        Write-Host "  Archivo: $rutaArchivo" -ForegroundColor Yellow
        Write-Host "  Detalle: $($_.Exception.Message)" -ForegroundColor Red
        throw
    }
}

# =====================================================================
# SCRIPT PRINCIPAL
# =====================================================================

Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host "  Limpiador de Caracteres No-ASCII" -ForegroundColor Cyan
Write-Host "  Elimina emojis, caracteres especiales y todo lo que no sea ASCII" -ForegroundColor Cyan
Write-Host "==================================================================" -ForegroundColor Cyan

Write-Host "`nBuscando archivos que coincidan con: $archivosAProcesar"

# Obtener lista de archivos
$archivos = Get-ChildItem -Path $archivosAProcesar -File -ErrorAction SilentlyContinue

if ($archivos.Count -eq 0) {
    Write-Host "`n[!] No se encontraron archivos que coincidan con el patron." -ForegroundColor Yellow
    Write-Host "[!] Verifica que el archivo existe o la ruta sea correcta." -ForegroundColor Yellow
    exit 0
}

Write-Host "Archivos encontrados: $($archivos.Count)`n" -ForegroundColor Green

# Confirmar procesamiento
Write-Host "Archivos a procesar:" -ForegroundColor Yellow
$archivos | ForEach-Object { Write-Host "  - $($_.FullName)" -ForegroundColor Gray }

if ($archivos.Count -gt 1) {
    Write-Host "`n[!] Se procesaran $($archivos.Count) archivos." -ForegroundColor Yellow
    $confirmar = Read-Host "Deseas continuar? (S/N)"
    
    if ($confirmar -notmatch '^[sS]$') {
        Write-Host "Operacion cancelada por el usuario." -ForegroundColor Yellow
        exit 0
    }
}

# Procesar cada archivo
$procesadosExitosamente = 0
$errores = 0

foreach ($archivo in $archivos) {
    try {
        Limpiar-ASCII -rutaArchivo $archivo.FullName `
                      -backup $crearBackup `
                      -verbose $mostrarCaracteresEliminados
        $procesadosExitosamente++
    } catch {
        $errores++
        Write-Host "  Continuando con el siguiente archivo...`n" -ForegroundColor Yellow
    }
}

# Resumen final
Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host "  Proceso completado" -ForegroundColor Cyan
Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host "[OK] Archivos procesados exitosamente: $procesadosExitosamente" -ForegroundColor Green

if ($errores -gt 0) {
    Write-Host "[ERROR] Archivos con errores: $errores" -ForegroundColor Red
}

if ($crearBackup) {
    Write-Host "`n[TIP] Los archivos originales fueron respaldados con extension .backup" -ForegroundColor Cyan
    Write-Host "      Puedes eliminar los backups si todo esta correcto.`n" -ForegroundColor Gray
}

# =====================================================================
# EJEMPLOS DE USO
# =====================================================================

<#
EJEMPLOS DE USO:

1. Archivo en el directorio actual:
   .\remove-non-ascii.ps1 archivo.txt

2. Ruta absoluta:
   .\remove-non-ascii.ps1 C:\Users\nombre\Desktop\documento.txt

3. Multiples archivos con comodin:
   .\remove-non-ascii.ps1 *.txt
   .\remove-non-ascii.ps1 C:\logs\*.log

4. Sin crear backup:
   .\remove-non-ascii.ps1 archivo.txt -sinBackup

5. Ver que caracteres se eliminan (modo verbose):
   .\remove-non-ascii.ps1 archivo.txt -verbose

6. Combinando opciones:
   .\remove-non-ascii.ps1 archivo.txt -sinBackup -verbose
#>

# =====================================================================
# FIN DEL SCRIPT
# =====================================================================
