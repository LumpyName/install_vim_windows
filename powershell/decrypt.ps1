# Script para desencriptar contenido Fernet (Python) y guardarlo en variable temporal
#
# USO:
#   .\decrypt.ps1 "gAAAAABm..." 
#   Password: ************

param (
    [Parameter(Mandatory=$true, Position=0)]
    [string]$contenidoEncriptado
)

$ErrorActionPreference = "Stop"

function Desencriptar-Fernet {
    param (
        [string]$tokenEncriptado,
        [string]$password
    )

    try {
        # Generar clave Fernet desde password (mismo metodo que Python)
        $sha256 = [System.Security.Cryptography.SHA256]::Create()
        $passwordBytes = [System.Text.Encoding]::UTF8.GetBytes($password)
        $claveHash = $sha256.ComputeHash($passwordBytes)
        $claveBase64 = [Convert]::ToBase64String($claveHash)
        
        # Decodificar token de Base64
        $tokenBytes = [Convert]::FromBase64String($tokenEncriptado)
        
        # Validar formato Fernet (version byte debe ser 0x80)
        if ($tokenBytes[0] -ne 0x80) {
            throw "Formato Fernet invalido. Version byte incorrecta."
        }
        
        # Extraer componentes del token Fernet
        # Formato: version (1) + timestamp (8) + iv (16) + ciphertext + hmac (32)
        $version = $tokenBytes[0]
        $timestamp = $tokenBytes[1..8]
        $iv = $tokenBytes[9..24]
        $ciphertext = $tokenBytes[25..($tokenBytes.Length - 33)]
        $hmac = $tokenBytes[($tokenBytes.Length - 32)..($tokenBytes.Length - 1)]
        
        # Verificar HMAC (autenticacion)
        $hmacsha256 = [System.Security.Cryptography.HMACSHA256]::new($claveHash[16..31])
        $dataParaHMAC = $tokenBytes[0..($tokenBytes.Length - 33)]
        $hmacCalculado = $hmacsha256.ComputeHash($dataParaHMAC)
        
        # Comparar HMACs (debe coincidir)
        $hmacValido = $true
        for ($i = 0; $i -lt 32; $i++) {
            if ($hmac[$i] -ne $hmacCalculado[$i]) {
                $hmacValido = $false
                break
            }
        }
        
        if (-not $hmacValido) {
            throw "HMAC invalido. Password incorrecta o token corrupto."
        }
        
        # Desencriptar usando AES-128-CBC
        $aes = [System.Security.Cryptography.Aes]::Create()
        $aes.KeySize = 128
        $aes.Key = $claveHash[0..15]  # Primeros 16 bytes para AES-128
        $aes.IV = $iv
        $aes.Mode = [System.Security.Cryptography.CipherMode]::CBC
        $aes.Padding = [System.Security.Cryptography.PaddingMode]::PKCS7
        
        $decryptor = $aes.CreateDecryptor()
        $resultado = $decryptor.TransformFinalBlock($ciphertext, 0, $ciphertext.Length)
        
        # Convertir a string
        $textoDesencriptado = [System.Text.Encoding]::UTF8.GetString($resultado)
        
        # Limpiar
        $aes.Dispose()
        $hmacsha256.Dispose()
        
        return $textoDesencriptado
        
    } catch {
        throw "Error al desencriptar: $($_.Exception.Message)"
    }
}

# =====================================================================
# SCRIPT PRINCIPAL
# =====================================================================

Write-Host ""
Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host "  Desencriptador Fernet -> Variable de Entorno Temporal" -ForegroundColor Cyan
Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host ""

# Pedir password de forma segura (oculta)
$securePassword = Read-Host "Password" -AsSecureString
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword)
$password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
[System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)

Write-Host ""
Write-Host "[PROCESO] Desencriptando contenido..." -ForegroundColor Yellow

try {
    # Desencriptar
    $valorDesencriptado = Desencriptar-Fernet -tokenEncriptado $contenidoEncriptado -password $password
    
    # Crear variable de entorno TEMPORAL
    [Environment]::SetEnvironmentVariable("MY_TOKEN", $valorDesencriptado, "Process")
    
    # Tambien establecer en la sesion actual
    $env:MY_TOKEN = $valorDesencriptado
    
    # Mensaje de exito
    Write-Host ""
    Write-Host "==================================================================" -ForegroundColor Green
    Write-Host "  [OK] Desencriptacion Exitosa!" -ForegroundColor Green
    Write-Host "==================================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "  Variable de entorno creada:" -ForegroundColor Cyan
    Write-Host "  Nombre: MY_TOKEN" -ForegroundColor White
    Write-Host "  Valor: $valorDesencriptado" -ForegroundColor White
    Write-Host ""
    Write-Host "  [INFO] Tipo: Variable TEMPORAL" -ForegroundColor Yellow
    Write-Host "  [INFO] Alcance: Solo esta sesion de terminal" -ForegroundColor Yellow
    Write-Host "  [INFO] Se borrara automaticamente al cerrar esta ventana" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Para usar la variable en esta sesion:" -ForegroundColor Cyan
    Write-Host "    echo `$env:MY_TOKEN" -ForegroundColor Gray
    Write-Host ""
    Write-Host "==================================================================" -ForegroundColor Green
    Write-Host ""
    
} catch {
    Write-Host ""
    Write-Host "==================================================================" -ForegroundColor Red
    Write-Host "  [ERROR] No se pudo desencriptar el contenido" -ForegroundColor Red
    Write-Host "==================================================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "  Posibles causas:" -ForegroundColor Yellow
    Write-Host "    - Password incorrecta" -ForegroundColor White
    Write-Host "    - Contenido no fue encriptado con Fernet (Python)" -ForegroundColor White
    Write-Host "    - Token corrupto o incompleto" -ForegroundColor White
    Write-Host ""
    Write-Host "  Detalle tecnico:" -ForegroundColor DarkGray
    Write-Host "  $($_.Exception.Message)" -ForegroundColor DarkGray
    Write-Host ""
    exit 1
}

# =====================================================================
# EJEMPLOS DE USO
# =====================================================================

<#
EJEMPLO DE USO COMPLETO:

1. PYTHON - Encriptar:
   from cryptography.fernet import Fernet
   import base64
   import hashlib
   
   def generar_clave(password):
       key = hashlib.sha256(password.encode()).digest()
       return base64.urlsafe_b64encode(key)
   
   password = "miPassword123"
   mensaje = "mi_token_secreto_12345"
   
   fernet = Fernet(generar_clave(password))
   encriptado = fernet.encrypt(mensaje.encode())
   print(encriptado.decode())
   
   # Resultado ejemplo: gAAAAABm5x2R3...

2. POWERSHELL - Desencriptar:
   .\decrypt.ps1 "gAAAAABm5x2R3..."
   Password: ************
   
3. USAR LA VARIABLE:
   echo $env:MY_TOKEN
   
4. VERIFICAR QUE ES TEMPORAL:
   - Cierra la terminal
   - Abre nueva terminal
   - echo $env:MY_TOKEN  # Estara vacio
#>

# =====================================================================
# FIN DEL SCRIPT
# =====================================================================