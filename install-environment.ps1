# PowerShell script para instalar Neovim y Python

# FUNCION QUE SE REPITEN EN EL CODIGO

function Descargar-Y-ExtraerPortable {
    param (
        [Parameter(Mandatory=$true)][string]$nombre,
        [Parameter(Mandatory=$true)][string]$url,
        [Parameter(Mandatory=$true)][string]$destZip,  # Para el archivo .zip
        [Parameter(Mandatory=$true)][string]$destExtract,  # Para la carpeta de destino
        [Parameter(Mandatory=$true)][string]$tipoArchivo  # 'zip' o 'exe'
    )

    Write-Host "`n Verificando disponibilidad del recurso para $nombre..."


    try {
        # Si el archivo ya existe, lo notificamos y salimos
        if (Test-Path $destZip) {
            Write-Host "El archivo $nombre ya existe en $destZip"
            return
        }

        # Descargar el archivo
        Write-Host " Descargando $nombre..."
        Invoke-WebRequest -Uri $url -OutFile $destZip

        # Procesar segÃºn el tipo de archivo
        switch ($tipoArchivo) {
            'zip' {
                Write-Host " Descomprimiendo $nombre Portable..."
                Expand-Archive -Path $destZip -DestinationPath $destExtract -Force
            }
            'exe' {
                Write-Host " Ejecutando el instalador de $nombre..."
                Start-Process -FilePath $destZip -ArgumentList "/quiet InstallAllUsers=1 PrependPath=1" -Wait
                Write-Host "`n La instalación de $nombre se completó correctamente."
            }
            default {
                Write-Host " Tipo de archivo no soportado: $tipoArchivo"
            }
        }

    }
    catch {
        Write-Host " No se pudo descargar o ejecutar el recurso en $url"
        Write-Host "   Detalle del error: $($_.Exception.Message)"
    }
}


function Crear-Carpeta ($ruta) {
    if (Test-Path -Path $ruta -PathType Container) {
        Write-Host " La carpeta ya existe: $ruta"
        return
    }

    try {
        New-Item -Path $ruta -ItemType Directory -Force | Out-Null
        Write-Host " Carpeta creada exitosamente: $ruta"
    } catch {
        Write-Host " Error al crear la carpeta: $($_.Exception.Message)"
    }
}


function Print-Finally ($path_exe){
    Start-Process -FilePath $path_exe -Wait

    Write-Host "`n Se han agregado las siguientes rutas al entorno del usuario (PATH):`n"

    $pathsToAdd | ForEach-Object {
        Write-Host "   â€¢ $_"
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

# CREAR LAS CARPETA PREPARANDO CARPETAS
Crear-Carpeta "$path_nvim\nvim"
Crear-Carpeta $path_nvim
Crear-Carpeta $path_toolsUser

# =====================================================================
# SI GIT NO ESTÃ INSTALADO AHORA LO INSTALAREMOS
# =====================================================================

if (!(Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "`n Git no esta¡ instalado. Instalando Git..."

    Descargar-Y-ExtraerPortable `
        -nombre      "Git" `
        -url         "https://github.com/git-for-windows/git/releases/download/v2.51.0-rc2.windows.1/MinGit-2.51.0-rc2-64-bit.zip" `
        -destZip     $path_gitzip `
        -destExtract $path_git `
        -tipoArchivo "zip"
}

# =====================================================================
# SE FINALIZÃ“ LA DESCARGA GIT O SE OMITIÃ“
# =====================================================================


# =====================================================================
# SI NVIM NO ESTÃ INSTALADO AHORA LO INSTALAREMOS
# =====================================================================

if (!(Get-Command nvim -ErrorAction SilentlyContinue)) {
    Write-Host "`n Nvim no esta¡ instalado. Instalando Nvim..."
    
    Descargar-Y-ExtraerPortable `
        -nombre      "Nvim" `
        -url         "https://github.com/neovim/neovim/releases/download/v0.11.3/nvim-win64.zip" `
        -destZip     $path_nvimzip `
        -destExtract $path_environment `
        -tipoArchivo "zip"
    
}

$initVimPath = "$path_nvim\nvim\init.vim"

if (!(Test-Path $initVimPath)) {
    Write-Host "¿ Descargando archivo init.vim..."
    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/LumpyName/install_vim_windows/main/config.init.vim" `
                      -OutFile $initVimPath
    Write-Host "¿ init.vim descargado en: $initVimPath"
} else {
    Write-Host "¿ El archivo init.vim ya existe en: $initVimPath ¿ no se descargará nuevamente."
}
# Verificar si la variable de entorno XDG_CONFIG_HOME ya estÃ¡ definida
$xdgVar = [System.Environment]::GetEnvironmentVariable("XDG_CONFIG_HOME", "User")

if ([string]::IsNullOrWhiteSpace($xdgVar)) {

    [System.Environment]::SetEnvironmentVariable("XDG_CONFIG_HOME", $path_nvim, "User")
    Write-Host "âœ… Variable de entorno XDG_CONFIG_HOME configurada con: $path_nvim"
} else {
    Write-Host " La variable de entorno XDG_CONFIG_HOME ya estÃ¡ definida como: $xdgVar"
}


# =====================================================================
# SE FINALIZÃ“ LA DESCARGA DE NVIM O SE OMITIÃ“
# =====================================================================

# =====================================================================
# SE FINALIZÃ“ LA DESCARGA E INSTALACIÃ“N DE GIT Y NVIM O SE OMITIÃ“
# Y SE COMIENZA A REALIZAR EL ULTIMO PASO PARA ESTO
# =====================================================================


Write-Host "`nAgregando el GIT, NVIM, Carpeta al PATH del usuario"
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

# Agregar cada ruta si no existe aÃºn
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
# SI PYTHON NO ESTÃ INSTALADO AHORA LO INSTALAREMOS
# =====================================================================

    # Ruta donde se guardara¡ el instalador
    $pythonInstaller = "$path_environment\python-3.13.7-amd64.exe"
    $requiredVersion = [Version]"3.13.7"

    # Verificar si Python esta instalado
    $python = Get-Command python -ErrorAction SilentlyContinue
    if (-not $python) {
        Write-Host "Python no esta¡ instalado."
        $instalar = Read-Host "Quieres instalar la ultima version de Python? (S/N)"
        if ($instalar -notmatch '^[sS]$') {
            Write-Host "Instalacion cancelada por el usuario."
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

    # Obtener versiÃ³n actual de Python
    $versionInfo = & python --version 2>&1
    $version = $versionInfo -replace '[^\d\.]', ''
    Write-Host "VersiÃ³n de Python encontrada: $version"

    try {
        $actualVersion = [Version]$version
    } catch {
        Write-Host "No se pudo determinar la versiÃ³n de Python. Puede estar mal instalado."
        Write-Host ""
        Write-Host "De todos modos descargamos el Portable entonces..."

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
        Write-Host " Python cumple con la versiÃ³n requerida (3.13.7 o superior)."
        return
    }

    Write-Host "La versin de Python es menor que 3.13.7."
    $instalar = Read-Host " ¿Quieres instalar la Ultima version de Python? (S/N)"
    if ($instalar -notmatch '^[sS]$') {
        Write-Host "InstalaciÃ³n cancelada por el usuario."
        return
    }


    Descargar-Y-ExtraerPortable `
        -nombre      "Python" `
        -url         "https://www.python.org/ftp/python/3.13.7/python-3.13.7-amd64.exe" `
        -destZip     $pythonInstaller `
        -destExtract $path_environment `
        -tipoArchivo "exe"

    Print-Finally $pythonInstaller

