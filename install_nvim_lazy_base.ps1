# 1. Descargar Neovim portable
$nvimUrl = "https://github.com/neovim/neovim/releases/download/v0.9.5/nvim-win64.zip"
$nvimZip = "$env:TEMP\nvim-win64.zip"
$nvimTarget = "$env:LOCALAPPDATA\nvim"

Invoke-WebRequest -Uri $nvimUrl -OutFile $nvimZip
Expand-Archive -Path $nvimZip -DestinationPath $nvimTarget -Force
Remove-Item $nvimZip

# 2. Agregar Neovim al PATH (opcional)
$binPath = "$nvimTarget\nvim-win64\bin"
if (-not ($env:Path -split ";" | Where-Object { $_ -eq $binPath })) {
    [Environment]::SetEnvironmentVariable("Path", "$env:Path;$binPath", [EnvironmentVariableTarget]::User)
    Write-Host "🔧 Neovim agregado al PATH"
}

# 3. Instalar LazyVim base
$lazyPath = "$env:LOCALAPPDATA\nvim\config"
New-Item -ItemType Directory -Path $lazyPath -Force

git clone https://github.com/LazyVim/starter $lazyPath
Remove-Item "$lazyPath\.git" -Recurse -Force

# 4. Copiar configuración a Neovim
$initPath = "$env:LOCALAPPDATA\nvim\nvim-win64\config"
New-Item -ItemType Directory -Path $initPath -Force
Copy-Item -Path "$lazyPath\*" -Destination $initPath -Recurse -Force

Write-Host "✅ Neovim + LazyVim base instalado sin plugins adicionales"
