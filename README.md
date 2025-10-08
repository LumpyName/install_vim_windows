# Development Tools Environment

> Coleccion de herramientas para configurar entorno de desarrollo multiplataforma

---

## Estructura del Proyecto

```
tools_environment/
├── python/                          # Python Scripts
│   ├── GenerateJSON.py              # JSON manager with encryption support
│   └── secret-vault.py              # Encrypted secrets manager (Fernet)
│
├── powershell/                      # PowerShell Scripts (Windows)
│   ├── install-environment.ps1      # Auto-installer: Git + Neovim + Python
│   ├── decrypt.ps1                  # Fernet decryptor -> ENV variable
│   └── remove-non-ascii.ps1         # ASCII cleaner utility
│
├── config/                          # Configuration Files
│   └── nvim/
│       └── init.vim                 # Neovim configuration
│
└── docs/                            # Documentation
    └── languaje_keyboard.txt        # Windows keyboard commands

```

---

## Quick Start

### Python Tools

**Secret Vault** - Manage encrypted keys
```bash
cd python
python secret-vault.py
```

**GenerateJSON** - JSON data manager
```python
from GenerateJSON import GenerateJSON

db = GenerateJSON("mydata.json")
db.key("API_TOKEN", value="secret123", end_date="31-12-2025")
db.save()
```

---

### PowerShell Tools (Windows)

**Install Development Environment**
```powershell
irm https://your-repo/powershell/install-environment.ps1 | iex
```

**Decrypt Fernet Token**
```powershell
.\powershell\decrypt.ps1 "gAAAAABm..."
# Creates temporary environment variable MY_TOKEN
```

**Clean Non-ASCII Characters**
```powershell
.\powershell\remove-non-ascii.ps1 file.txt
```

---

## Neovim Setup

### Linux/MacOS
```bash
mkdir -p ~/.config/nvim
cp config/nvim/init.vim ~/.config/nvim/
```

### Windows
```powershell
mkdir -Force $env:LOCALAPPDATA\nvim
copy config\nvim\init.vim $env:LOCALAPPDATA\nvim\
```

---

## Requirements

### Python
```bash
pip install cryptography
```

### PowerShell (Windows)
- PowerShell 5.1 or higher
- Administrator privileges (for some installations)

---

## Features

- [x] Cross-platform configuration management
- [x] Encrypted secrets storage (Fernet)
- [x] Automated development environment setup
- [x] ASCII-only file sanitizer
- [x] Portable Neovim configuration

---

## Tools Overview

### Python Scripts

| Script | Description |
|--------|-------------|
| `GenerateJSON.py` | Manages JSON files with automatic timestamps and date tracking |
| `secret-vault.py` | Interactive CLI for storing encrypted API keys and tokens |

### PowerShell Scripts

| Script | Description |
|--------|-------------|
| `install-environment.ps1` | One-command setup for Git, Neovim, and Python on Windows |
| `decrypt.ps1` | Decrypts Fernet tokens and creates temporary environment variables |
| `remove-non-ascii.ps1` | Removes emojis and non-ASCII characters from files |

---

## Usage Examples

### Encrypting Secrets (Python)
```bash
cd python
python secret-vault.py

# Follow interactive prompts:
# 1. Enter decryption password
# 2. Add key names and values
# 3. Set expiration dates
# 4. Done! Encrypted file created
```

### Installing Dev Environment (Windows)
```powershell
# One-liner installation
irm https://raw.githubusercontent.com/your-user/your-repo/main/powershell/install-environment.ps1 | iex
```

### Cleaning Files
```bash
# Remove non-ASCII from a file
cd powershell
pwsh remove-non-ascii.ps1 myfile.txt

# With verbose output
pwsh remove-non-ascii.ps1 myfile.txt -verbose
```

---

## License

Free to use. No warranties.

---

## Author

Created for personal development environment setup

**Last Updated:** 2025-10-07