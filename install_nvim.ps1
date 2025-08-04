# URL de la versión portable de Neovim (ajusta si hay una versión más reciente)
$nvimUrl = "https://github.com/neovim/neovim/releases/download/v0.9.5/nvim-win64.zip"
$nvimZip = "$env:TEMP\nvim-win64.zip"
$nvimTarget = "$env:LOCALAPPDATA\nvim"

# Descargar Neovim
Invoke-WebRequest -Uri $nvimUrl -OutFile $nvimZip

# Crear carpeta destino
New-Item -ItemType Directory -Path $nvimTarget -Force

# Extraer el ZIP
Expand-Archive -Path $nvimZip -DestinationPath $nvimTarget -Force

# Eliminar el ZIP
Remove-Item $nvimZip

# (Opcional) Agregar al PATH si no está
$binPath = "$nvimTarget\nvim-win64\bin"
if (-not ($env:Path -split ";" | Where-Object { $_ -eq $binPath })) {
    [Environment]::SetEnvironmentVariable("Path", "$env:Path;$binPath", [EnvironmentVariableTarget]::User)
    Write-Host "🔧 Neovim agregado al PATH"
}

Write-Host "✅ Neovim instalado silenciosamente en $nvimTarget"
