<#
.SYNOPSIS
    Configura un equipo Windows nuevo con mi shell y mi VS Code.
.DESCRIPTION
    - Instala programas con winget (git, PowerShell 7, oh-my-posh, VS Code)
    - Instala modulos de PowerShell (Terminal-Icons, CompletionPredictor)
    - Instala la fuente UbuntuMono Nerd Font
    - Enlaza (symlink) perfiles de PowerShell, tema oh-my-posh y ajustes de VS Code
    - Instala las extensiones de VS Code listadas en vscode/extensions.txt
    Los archivos existentes se respaldan como *.bak antes de reemplazarse.
.EXAMPLE
    git clone https://github.com/<usuario>/dotfiles $HOME\dotfiles
    cd $HOME\dotfiles
    .\bootstrap.ps1
.EXAMPLE
    .\bootstrap.ps1 -SkipExtensions -SkipPackages
#>
[CmdletBinding()]
param(
    [switch]$SkipPackages,
    [switch]$SkipExtensions,
    [switch]$Copy   # copiar archivos en lugar de crear symlinks (no requiere Modo desarrollador)
)

$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot

function Write-Step($msg) { Write-Host "==> $msg" -ForegroundColor Cyan }

function Link-File {
    param([string]$Target, [string]$Path)

    New-Item -ItemType Directory -Force (Split-Path $Path) | Out-Null

    $item = Get-Item $Path -Force -ErrorAction SilentlyContinue
    if ($item) {
        if ($item.LinkType -eq 'SymbolicLink' -and $item.Target -contains $Target) {
            Write-Host "    ya enlazado: $Path"
            return
        }
        if ($item.LinkType) {
            Remove-Item $Path -Force
        } else {
            Move-Item $Path "$Path.bak" -Force
            Write-Host "    respaldo: $Path.bak"
        }
    }

    if ($Copy) {
        Copy-Item $Target $Path
        Write-Host "    copiado: $Path"
    } else {
        try {
            New-Item -ItemType SymbolicLink -Path $Path -Target $Target | Out-Null
            Write-Host "    enlazado: $Path -> $Target"
        } catch {
            Write-Warning "No se pudo crear el symlink (activa el Modo desarrollador o ejecuta como admin). Copiando."
            Copy-Item $Target $Path
        }
    }
}

# 1. Programas
if (-not $SkipPackages) {
    Write-Step 'Instalando programas con winget'
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Warning 'winget no esta disponible; instala "App Installer" desde la Microsoft Store.'
    } else {
        $packages = @(
            'Git.Git',
            'Microsoft.PowerShell',
            'JanDeDobbeleer.OhMyPosh',
            'Microsoft.VisualStudioCode'
        )
        foreach ($p in $packages) {
            winget install --id $p -e --silent --accept-package-agreements --accept-source-agreements
        }
    }

    Write-Step 'Instalando modulos de PowerShell'
    if (-not (Get-PSRepository PSGallery -ErrorAction SilentlyContinue)) { Register-PSRepository -Default }
    foreach ($m in 'Terminal-Icons', 'CompletionPredictor', 'PSReadLine') {
        if (-not (Get-Module -ListAvailable $m)) {
            Install-Module $m -Scope CurrentUser -Force -AllowClobber
        }
    }

    Write-Step 'Instalando fuente UbuntuMono Nerd Font'
    # oh-my-posh puede no estar en el PATH de esta sesion todavia
    $omp = Get-Command oh-my-posh -ErrorAction SilentlyContinue
    if ($omp) { oh-my-posh font install UbuntuMono } else { Write-Warning 'Reabre la terminal y ejecuta: oh-my-posh font install UbuntuMono' }
}

# 2. Variable DOTFILES (la usa el perfil para ubicar scripts y tema)
Write-Step "Definiendo DOTFILES=$root"
[Environment]::SetEnvironmentVariable('DOTFILES', $root, 'User')
$env:DOTFILES = $root

# 3. PowerShell: perfil unificado para 5.1 y 7+
Write-Step 'Enlazando perfiles de PowerShell'
$profileSrc = Join-Path $root 'powershell\Microsoft.PowerShell_profile.ps1'
$docs = [Environment]::GetFolderPath('MyDocuments')
Link-File $profileSrc (Join-Path $docs 'WindowsPowerShell\Microsoft.PowerShell_profile.ps1')
Link-File $profileSrc (Join-Path $docs 'PowerShell\Microsoft.PowerShell_profile.ps1')

# 4. VS Code
Write-Step 'Enlazando ajustes de VS Code'
$codeUser = Join-Path $env:APPDATA 'Code\User'
Link-File (Join-Path $root 'vscode\keybindings.json') (Join-Path $codeUser 'keybindings.json')

# settings.json: si ya existe, NO se reemplaza (puede tener tus conexiones/cuentas).
$settingsDst = Join-Path $codeUser 'settings.json'
if (Test-Path $settingsDst) {
    Write-Warning "Ya existe $settingsDst. No se sobrescribe; copia a mano lo que quieras de vscode\settings.json."
} else {
    Link-File (Join-Path $root 'vscode\settings.json') $settingsDst
}

# 5. Extensiones de VS Code
if (-not $SkipExtensions) {
    Write-Step 'Instalando extensiones de VS Code'
    if (Get-Command code -ErrorAction SilentlyContinue) {
        $installed = code --list-extensions
        Get-Content (Join-Path $root 'vscode\extensions.txt') |
            Where-Object { $_ -and ($_ -notin $installed) } |
            ForEach-Object { code --install-extension $_ --force }
    } else {
        Write-Warning 'El comando "code" no esta en el PATH. Reabre la terminal y vuelve a ejecutar con -SkipPackages.'
    }
}

Write-Host "`nListo. Cierra y abre la terminal. En VS Code, la fuente del terminal es 'UbuntuMono Nerd Font Mono'." -ForegroundColor Green
