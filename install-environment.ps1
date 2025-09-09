# PowerShell script para instalar Neovim y Python

# FUNCIONES QUE SE REPITEN EN EL CÓDIGO

function Descargar-Y-ExtraerPortable {
    param (
        [Parameter(Mandatory = $true)][string]$nombre,
        [Parameter(Mandatory = $true)][string]$url,
        [Parameter(Mandatory = $true)][string]$destZip,        # Ruta del archivo .zip o .exe
        [Parameter(Mandatory = $true)][string]$destExtract,    # Carpeta de destino
        [Parameter(Mandatory = $true)][string]$tipoArchivo     # 'zip' o 'exe'
    )

    Write-Host "`nVerificando disponibilidad del recurso para $nombre..."

    try {
        # Si el archivo ya existe, lo notificamos y salimos
        if (Test-Path $destZip) {
            Write-Host "El archivo $nombre ya existe en $destZip"
            return
        }

        # Descargar el archivo
        Write-Host "Descargando $nombre..."
        Invoke-WebRequest -Uri $url -OutFile $destZip

        # Procesar según el tipo de archivo
        switch ($tipoArchivo) {
            'zip' {
                Write-Host "Descomprimiendo $nombre Portable..."
                Expand-Archive -Path $destZip -DestinationPath $destExtract -Force
            }
            'exe' {
                Write-Host "Ejecutando el instalador de $nombre..."
                Start-Process -FilePath $destZip -ArgumentList "/quiet InstallAllUsers=1 PrependPath=1" -Wait
                Write-Host "La instalación de $nombre se completó correctamente."
            }
            default {
                Write-Host "Tipo de archivo no soportado: $tipoArchivo"
            }
        }

    } catch {
        Write-Host "No se pudo descargar o ejecutar el recurso en $url"
        Write-Host "Detalle del error: $($_.Exception.Message)"
    }
}

function Crear-Carpeta {
    param ([string]$ruta)

    if (Test-Path -Path $ruta -PathType Container) {
        Write-Host "La carpeta ya existe: $ruta"
        return
    }

    try {
        New-Item -Path $ruta -ItemType Directory -Force | Out-Null
        Write-Host "Carpeta creada exitosamente: $ruta"
    } catch {
        Write-Host "Error al crear la carpeta: $($_.Exception.Message)"
    }
}

function Print-Finally {
    param ([string]$path_exe, [array]$pathsToAdd)

    Start-Process -FilePath $path_exe -Wait

    Write-Host "`nSe han agregado las siguientes rutas al entorno del usuario (PATH):`n"

    $pathsToAdd | ForEach-Object {
        Write-Host " - $_"
    }
}

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
Crear-Carpeta "$path_nvim\nvim"
Crear-Carpeta $path_nvim
Crear-Carpeta $path_toolsUser

# =====================================================================
# SI GIT NO ESTÁ INSTALADO, SE INSTALA
# =====================================================================

if (!(Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "`nGit no está instalado. Instalando Git..."

    Descargar-Y-ExtraerPortable `
        -nombre      "Git" `
        -url         "https://github.com/git-for-windows/git/releases/download/v2.51.0-rc2.windows.1/MinGit-2.51.0-rc2-64-bit.zip" `
        -destZip     $path_gitzip `
        -destExtract $path_git `
        -tipoArchivo "zip"
}

# =====================================================================
# FIN DE DESCARGA DE GIT
# =====================================================================

# =====================================================================
# SI NVIM NO ESTÁ INSTALADO, SE INSTALA
# =====================================================================

if (!(Get-Command nvim -ErrorAction SilentlyContinue)) {
    Write-Host "`nNvim no está instalado. Instalando Nvim..."
    
    Descargar-Y-ExtraerPortable `
        -nombre      "Nvim" `
        -url         "https://github.com/neovim/neovim/releases/download/v0.11.3/nvim-win64.zip" `
        -destZip     $path_nvimzip `
        -destExtract $path_environment `
        -tipoArchivo "zip"
}

# =====================================================================
# CONFIGURACIÓN DE init.vim
# =====================================================================

$initVimPath = "$path_nvim\nvim\init.vim"

if (!(Test-Path $initVimPath)) {
    Write-Host "Descargando archivo init.vim..."
    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/LumpyName/install_vim_windows/main/config.init.vim" `
                      -OutFile $initVimPath
    Write-Host "init.vim descargado en: $initVimPath"
} else {Write-Host "El archivo init.vim ya existe en: $initVimPath no se descargará nuevamente."}

# =====================================================================
# CONFIGURACIÓN DE VARIABLE DE ENTORNO
# =====================================================================

$xdgVar = [System.Environment]::GetEnvironmentVariable("XDG_CONFIG_HOME", "User")

if ([string]::IsNullOrWhiteSpace($xdgVar) -or $xdgVar -ne $path_nvim) {
    [System.Environment]::SetEnvironmentVariable("XDG_CONFIG_HOME", $path_nvim, "User")
    Write-Host "Variable de entorno XDG_CONFIG_HOME configurada con: $path_nvim"
} else {
    Write-Host "La variable de entorno XDG_CONFIG_HOME ya está definida como: $xdgVar"
}

# =====================================================================
# FIN DE DESCARGA/INSTALACIÓN DE NVIM
# =====================================================================


# =====================================================================
# FINALIZA INSTALACIÓN DE GIT Y NVIM O SE OMITIÓ
# COMIENZA LA CONFIGURACIÓN FINAL
# =====================================================================

Write-Host "`nAgregando Git, Nvim y herramientas al PATH del usuario..."
$pathsToAdd = @(
    "$path_git\cmd",
    "$path_git\mingw64\bin",
    "$path_nvimbin",
    "$path_toolsUser"
)

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

# =====================================================================
# SI PYTHON NO ESTÁ INSTALADO, SE INSTALA
# =====================================================================

# Ruta donde se guardará el instalador
$pythonInstaller = "$path_environment\python-3.13.7-amd64.exe"
$requiredVersion = [Version]"3.13.7"

# Verificar si Python está instalado
$python = Get-Command python -ErrorAction SilentlyContinue
if (-not $python) {
    Write-Host "Python no está instalado."
    $instalar = Read-Host "¿Quieres instalar la última versión de Python? (S/N)"
    if ($instalar -notmatch '^[sS]$') {
        Write-Host "Instalación cancelada por el usuario."
        return
    }

    Descargar-Y-ExtraerPortable `
        -nombre      "Python" `
        -url         "https://www.python.org/ftp/python/3.13.7/python-3.13.7-amd64.exe" `
        -destZip     $pythonInstaller `
        -destExtract $path_environment `
        -tipoArchivo "exe"

    Print-Finally $pythonInstaller
    return
}

# Obtener versión actual de Python
$versionInfo = & python --version 2>&1
$version = $versionInfo -replace '[^\d\.]', ''
Write-Host "Versión de Python encontrada: $version"

try {
    $actualVersion = [Version]$version
} catch {
    Write-Host "No se pudo determinar la versión de Python. Puede estar mal instalado."
    Write-Host "Descargando versión portable..."

    Descargar-Y-ExtraerPortable `
        -nombre      "Python" `
        -url         "https://www.python.org/ftp/python/3.13.7/python-3.13.7-amd64.exe" `
        -destZip     $pythonInstaller `
        -destExtract $path_environment `
        -tipoArchivo "exe"

    Print-Finally $pythonInstaller
    return
}

if ($actualVersion -ge $requiredVersion) {
    Write-Host "Python cumple con la versión requerida (3.13.7 o superior)."
    return
}

Write-Host "La versión de Python es menor que 3.13.7."
$instalar = Read-Host "¿Quieres instalar la última versión de Python? (S/N)"
if ($instalar -notmatch '^[sS]$') {
    Write-Host "Instalación cancelada por el usuario."
    return
}

Descargar-Y-ExtraerPortable `
    -nombre      "Python" `
    -url         "https://www.python.org/ftp/python/3.13.7/python-3.13.7-amd64.exe" `
    -destZip     $pythonInstaller `
    -destExtract $path_environment `
    -tipoArchivo "exe"

Print-Finally $pythonInstaller
