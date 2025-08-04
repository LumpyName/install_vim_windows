# URL del instalador de Git (ajusta la versión si es necesario)
$gitUrl = "https://github.com/git-for-windows/git/releases/download/v2.41.0.windows.1/Git-2.41.0-64-bit.exe"
$gitInstaller = "$env:TEMP\GitInstaller.exe"

# Descargar el instalador
Invoke-WebRequest -Uri $gitUrl -OutFile $gitInstaller

# Ejecutar instalación silenciosa
Start-Process -FilePath $gitInstaller -ArgumentList "/VERYSILENT", "/NORESTART" -Wait

# Eliminar el instalador
Remove-Item $gitInstaller

Write-Host "✅ Git instalado silenciosamente desde PowerShell"
