# Perfil unificado para Windows PowerShell 5.1 y PowerShell 7+.
# bootstrap.ps1 lo enlaza (symlink) a las rutas reales de $PROFILE.

# Raiz del repo dotfiles (la define bootstrap.ps1; por defecto ~\dotfiles)
$DotfilesRoot = if ($env:DOTFILES) { $env:DOTFILES } else { Join-Path $HOME 'dotfiles' }

# --- Funciones utiles ---
function Show-Tree {
    param (
        [string]$Path = ".",
        [int]$Level = 0,
        [string[]]$ExcludeFolders = @('.git', '.vscode', '.venv', '.venv-wsl', 'bin', 'node_modules', 'dist', 'obj')
    )

    $items = Get-ChildItem -Path $Path

    foreach ($item in $items) {
        if ($item.Name -notin $ExcludeFolders) {
            $indent = " " * ($Level * 4)
            Write-Host ("$indent" + "+ " + $item.Name)

            if ($item.PSIsContainer) {
                Show-Tree -Path $item.FullName -Level ($Level + 1) -ExcludeFolders $ExcludeFolders
            }
        }
    }
}

# Requiere terminal como administrador
function Kill-Port { & (Join-Path $DotfilesRoot 'powershell\scripts\Kill-Port.ps1') @args }

# --- Estilo Ubuntu (oh-my-posh) ---
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    $ompConfig = Join-Path $DotfilesRoot 'oh-my-posh\ubuntu.omp.json'
    if (Test-Path $ompConfig) {
        oh-my-posh init pwsh --config $ompConfig | Invoke-Expression
    }
}

# --- PSReadLine ---
if ($PSVersionTable.PSVersion.Major -ge 7 -or (Get-Module -ListAvailable PSReadLine | Where-Object Version -ge '2.1')) {
    # Predicciones tipo VS Code: historial + plugins (CompletionPredictor), en lista desplegable
    if (Get-Module -ListAvailable CompletionPredictor) { Import-Module CompletionPredictor }
    try {
        Set-PSReadLineOption -PredictionSource HistoryAndPlugin -PredictionViewStyle ListView -ErrorAction Stop
    } catch {
        try { Set-PSReadLineOption -PredictionSource History -PredictionViewStyle InlineView -ErrorAction Stop } catch {}
    }
}
Set-PSReadLineOption -EditMode Emacs
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
# Flechas arriba/abajo: buscar en el historial segun lo escrito
Set-PSReadLineKeyHandler -Key UpArrow   -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward

# --- Alias estilo Linux ---
function ll { Get-ChildItem -Force @args }
function la { Get-ChildItem -Force @args }
function which($n) { (Get-Command $n -ErrorAction SilentlyContinue).Source }
function touch($f) { if (Test-Path $f) { (Get-Item $f).LastWriteTime = Get-Date } else { New-Item -ItemType File $f | Out-Null } }

if (Get-Module -ListAvailable Terminal-Icons) { Import-Module Terminal-Icons }
