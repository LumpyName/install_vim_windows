# PowerShell script para instalar Neovim, Git y Python
# Con manejo robusto de errores

# Configurar para que errores no capturados detengan el script
$ErrorActionPreference = "Stop"

# =====================================================================
# FUNCIONES PRINCIPALES
# =====================================================================

function Descargar-Y-ExtraerPortable {
    param (
        [Parameter(Mandatory = $true)][string]$nombre,
        [Parameter(Mandatory = $true)][string]$url,
        [Parameter(Mandatory = $true)][string]$destZip,
        [Parameter(Mandatory = $true)][string]$destExtract,
        [Parameter(Mandatory = $true)][string]$tipoArchivo
    )

    Write-Host "`nVerificando disponibilidad del recurso para $nombre..."

    try {
        # Si el archivo ya existe, lo notificamos y salimos de la funcion
        if (Test-Path $destZip) {
            Write-Host "El archivo $nombre ya existe en $destZip"
            return $true
        }

        # Descargar el archivo
        Write-Host "Descargando $nombre desde $url..."
        Invoke-WebRequest -Uri $url -OutFile $destZip -ErrorAction Stop

        # Verificar que se descargo correctamente
        if (!(Test-Path $destZip)) {
            throw "El archivo no se descargo correctamente: $destZip"
        }

        Write-Host "Descarga completada exitosamente."

        # Procesar segun el tipo de archivo
        switch ($tipoArchivo) {
            'zip' {
                Write-Host "Descomprimiendo $nombre Portable..."
                Expand-Archive -Path $destZip -DestinationPath $destExtract -Force -ErrorAction Stop
                Write-Host "Descompresion completada."
            }
            'exe' {
                Write-Host "Ejecutando el instalador de $nombre..."
                $process = Start-Process -FilePath $destZip -ArgumentList "/quiet InstallAllUsers=1 PrependPath=1" -Wait -PassThru
                
                if ($process.ExitCode -ne 0) {
                    throw "El instalador de $nombre fallo con codigo de salida: $($process.ExitCode)"
                }
                
                Write-Host "La instalacion de $nombre se completo correctamente."
            }
            default {
                throw "Tipo de archivo no soportado: $tipoArchivo"
            }
        }

        return $true

    } catch {
        Write-Host "`n[ERROR CRITICO] Error al procesar $nombre" -ForegroundColor Red
        Write-Host "URL: $url" -ForegroundColor Yellow
        Write-Host "Detalle del error:" -ForegroundColor Yellow
        Write-Host $_.Exception.Message -ForegroundColor Red
        Write-Host $_.ScriptStackTrace -ForegroundColor DarkGray
        exit 1
    }
}

function Crear-Carpeta {
    param ([string]$ruta)

    if (Test-Path -Path $ruta -PathType Container) {
        Write-Host "La carpeta ya existe: $ruta"
        return $true
    }

    try {
        New-Item -Path $ruta -ItemType Directory -Force -ErrorAction Stop | Out-Null
        Write-Host "Carpeta creada exitosamente: $ruta"
        return $true
    } catch {
        Write-Host "`n[ERROR CRITICO] Error al crear carpeta" -ForegroundColor Red
        Write-Host "Ruta: $ruta" -ForegroundColor Yellow
        Write-Host "Detalle del error:" -ForegroundColor Yellow
        Write-Host $_.Exception.Message -ForegroundColor Red
        Write-Host $_.ScriptStackTrace -ForegroundColor DarkGray
        exit 1
    }
}

function Agregar-AlPATH {
    param ([array]$pathsToAdd)

    Write-Host "`nAgregando rutas al PATH del usuario..."
    
    try {
        # Obtener el PATH actual del usuario
        $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
        
        # Convertir el PATH en una lista
        $currentPathList = $currentPath.Split(";")
        
        # Agregar cada ruta si no existe
        foreach ($path in $pathsToAdd) {
            if (-not ($currentPathList -contains $path)) {
                $currentPathList += $path
                Write-Host "Ruta agregada: $path"
            } else {
                Write-Host "La ruta ya estaba presente: $path"
            }
        }
        
        # Unir las rutas y actualizar el PATH de usuario
        $newPath = ($currentPathList -join ";")
        [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
        
        Write-Host "PATH actualizado correctamente." -ForegroundColor Green
        return $true
        
    } catch {
        Write-Host "`n[ERROR CRITICO] Error al actualizar el PATH" -ForegroundColor Red
        Write-Host "Detalle del error:" -ForegroundColor Yellow
        Write-Host $_.Exception.Message -ForegroundColor Red
        Write-Host $_.ScriptStackTrace -ForegroundColor DarkGray
        exit 1
    }
}

# =====================================================================
# INICIO DEL SCRIPT PRINCIPAL
# =====================================================================

Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host "  Script de instalacion de Entorno de Desarrollo" -ForegroundColor Cyan
Write-Host "  Git + Neovim + Python" -ForegroundColor Cyan
Write-Host "==================================================================" -ForegroundColor Cyan

# DEFINIR RUTAS
$path_nvim = "C:\ProgrammingEnvironment\config_nvim"
$path_environment = "C:\ProgrammingEnvironment"
$path_toolsUser = "$path_environment\toolsUser"

# Para GIT
$path_git = "$path_environment\tools_git"
$path_gitzip = "$path_environment\MinGit-64.zip"

# Para NVIM
$path_nvimzip = "$path_environment\nvim-win64.zip"
$path_nvimbin = "$path_environment\nvim-win64\bin"

# CREAR LAS CARPETAS
Write-Host "`n[PASO 1] Creando estructura de carpetas..." -ForegroundColor Cyan
Crear-Carpeta "$path_nvim\nvim"
Crear-Carpeta $path_nvim
Crear-Carpeta $path_toolsUser

# =====================================================================
# INSTALACION DE GIT
# =====================================================================

Write-Host "`n[PASO 2] Verificando instalacion de Git..." -ForegroundColor Cyan

if (!(Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "Git no esta instalado. Procediendo con la instalacion..."

    Descargar-Y-ExtraerPortable `
        -nombre      "Git" `
        -url         "https://github.com/git-for-windows/git/releases/download/v2.51.0-rc2.windows.1/MinGit-2.51.0-rc2-64-bit.zip" `
        -destZip     $path_gitzip `
        -destExtract $path_git `
        -tipoArchivo "zip"
    
    Write-Host "[OK] Git instalado correctamente." -ForegroundColor Green
} else {
    Write-Host "[OK] Git ya esta instalado." -ForegroundColor Green
}

# =====================================================================
# INSTALACION DE NEOVIM
# =====================================================================

Write-Host "`n[PASO 3] Verificando instalacion de Neovim..." -ForegroundColor Cyan

if (!(Get-Command nvim -ErrorAction SilentlyContinue)) {
    Write-Host "Nvim no esta instalado. Procediendo con la instalacion..."
    
    Descargar-Y-ExtraerPortable `
        -nombre      "Nvim" `
        -url         "https://github.com/neovim/neovim/releases/download/v0.11.3/nvim-win64.zip" `
        -destZip     $path_nvimzip `
        -destExtract $path_environment `
        -tipoArchivo "zip"
    
    Write-Host "[OK] Neovim instalado correctamente." -ForegroundColor Green
} else {
    Write-Host "[OK] Neovim ya esta instalado." -ForegroundColor Green
}

# =====================================================================
# CONFIGURACION DE init.vim
# =====================================================================

Write-Host "`n[PASO 4] Configurando init.vim..." -ForegroundColor Cyan

$initVimPath = "$path_nvim\nvim\init.vim"

try {
    if (!(Test-Path $initVimPath)) {
        Write-Host "Descargando archivo init.vim..."
        Invoke-WebRequest -Uri "https://raw.githubusercontent.com/LumpyName/install_vim_windows/main/config.init.vim" `
                          -OutFile $initVimPath -ErrorAction Stop
        
        if (!(Test-Path $initVimPath)) {
            throw "El archivo init.vim no se descargo correctamente"
        }
        
        Write-Host "[OK] init.vim descargado en: $initVimPath" -ForegroundColor Green
    } else {
        Write-Host "[OK] El archivo init.vim ya existe en: $initVimPath" -ForegroundColor Green
    }
} catch {
    Write-Host "`n[ERROR CRITICO] Error al descargar init.vim" -ForegroundColor Red
    Write-Host "Detalle del error:" -ForegroundColor Yellow
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor DarkGray
    exit 1
}

# =====================================================================
# CONFIGURACION DE VARIABLE DE ENTORNO XDG_CONFIG_HOME
# =====================================================================

Write-Host "`n[PASO 5] Configurando variable de entorno XDG_CONFIG_HOME..." -ForegroundColor Cyan

try {
    $xdgVar = [System.Environment]::GetEnvironmentVariable("XDG_CONFIG_HOME", "User")

    if ([string]::IsNullOrWhiteSpace($xdgVar) -or $xdgVar -ne $path_nvim) {
        [System.Environment]::SetEnvironmentVariable("XDG_CONFIG_HOME", $path_nvim, "User")
        Write-Host "[OK] Variable de entorno XDG_CONFIG_HOME configurada con: $path_nvim" -ForegroundColor Green
    } else {
        Write-Host "[OK] La variable de entorno XDG_CONFIG_HOME ya esta definida como: $xdgVar" -ForegroundColor Green
    }
} catch {
    Write-Host "`n[ERROR CRITICO] Error al configurar XDG_CONFIG_HOME" -ForegroundColor Red
    Write-Host "Detalle del error:" -ForegroundColor Yellow
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor DarkGray
    exit 1
}

# =====================================================================
# ACTUALIZACION DEL PATH
# =====================================================================

Write-Host "`n[PASO 6] Actualizando PATH del usuario..." -ForegroundColor Cyan

$pathsToAdd = @(
    "$path_git\cmd",
    "$path_git\mingw64\bin",
    "$path_nvimbin",
    "$path_toolsUser"
)

Agregar-AlPATH -pathsToAdd $pathsToAdd

# =====================================================================
# INSTALACION DE PYTHON
# =====================================================================

Write-Host "`n[PASO 7] Verificando instalacion de Python..." -ForegroundColor Cyan

$pythonInstaller = "$path_environment\python-3.13.7-amd64.exe"
$requiredVersion = [Version]"3.13.7"
$necesitaInstalacion = $false

# Verificar si Python esta instalado
$python = Get-Command python -ErrorAction SilentlyContinue

if (-not $python) {
    Write-Host "Python no esta instalado."
    $instalar = Read-Host "Quieres instalar Python 3.13.7? (S/N)"
    
    if ($instalar -match '^[sS]$') {
        $necesitaInstalacion = $true
    } else {
        Write-Host "[!] Instalacion de Python omitida por el usuario." -ForegroundColor Yellow
    }
} else {
    # Obtener version actual de Python
    $versionInfo = & python --version 2>&1
    $version = $versionInfo -replace '[^\d\.]', ''
    Write-Host "Version de Python encontrada: $version"

    try {
        $actualVersion = [Version]$version
        
        if ($actualVersion -ge $requiredVersion) {
            Write-Host "[OK] Python cumple con la version requerida (3.13.7 o superior)." -ForegroundColor Green
        } else {
            Write-Host "La version de Python es menor que 3.13.7."
            $instalar = Read-Host "Quieres instalar Python 3.13.7? (S/N)"
            
            if ($instalar -match '^[sS]$') {
                $necesitaInstalacion = $true
            } else {
                Write-Host "[!] Actualizacion de Python omitida por el usuario." -ForegroundColor Yellow
            }
        }
    } catch {
        Write-Host "[!] No se pudo determinar la version de Python correctamente." -ForegroundColor Yellow
        $instalar = Read-Host "Quieres instalar Python 3.13.7? (S/N)"
        
        if ($instalar -match '^[sS]$') {
            $necesitaInstalacion = $true
        } else {
            Write-Host "[!] Instalacion de Python omitida por el usuario." -ForegroundColor Yellow
        }
    }
}

# Instalar Python si es necesario
if ($necesitaInstalacion) {
    Descargar-Y-ExtraerPortable `
        -nombre      "Python" `
        -url         "https://www.python.org/ftp/python/3.13.7/python-3.13.7-amd64.exe" `
        -destZip     $pythonInstaller `
        -destExtract $path_environment `
        -tipoArchivo "exe"
    
    Write-Host "[OK] Python 3.13.7 instalado correctamente." -ForegroundColor Green
    Write-Host "`n[!] IMPORTANTE: Reinicia tu terminal para que los cambios surtan efecto." -ForegroundColor Yellow
}

# =====================================================================
# FIN DE LA INSTALACION BASE
# =====================================================================

Write-Host "`n==================================================================" -ForegroundColor Cyan
Write-Host "  [OK] Instalacion completada exitosamente" -ForegroundColor Green
Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host "`nRutas agregadas al PATH del usuario:"
$pathsToAdd | ForEach-Object {
    Write-Host "  - $_" -ForegroundColor Gray
}
Write-Host "`n[!] Recuerda: Reinicia tu terminal para que los cambios surtan efecto.`n" -ForegroundColor Yellow

# =====================================================================
# AQUI PUEDES AGREGAR MAS CODIGO PARA OTRAS TAREAS
# =====================================================================

# Ejemplo de codigo adicional que ahora SI se ejecutara:
# Write-Host "`n[PASO 8] Configurando herramientas adicionales..." -ForegroundColor Cyan
# Tu codigo aqui...

# =====================================================================
# FIN DEL SCRIPT
# =====================================================================
