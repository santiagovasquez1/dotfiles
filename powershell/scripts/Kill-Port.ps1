#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Mata todos los procesos que estén escuchando en un puerto TCP dado.
.EXAMPLE
    Kill-Port 10000
    Kill-Port 7071
#>
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [int]$Port
)

$found = netstat -ano | Select-String ":$Port\s"

if (-not $found) {
    Write-Host "No hay procesos usando el puerto $Port." -ForegroundColor Yellow
    exit 0
}

$procIds = $found |
    ForEach-Object { ($_ -split '\s+')[-1] } |
    Where-Object { $_ -match '^\d+$' } |
    Sort-Object -Unique

foreach ($procId in $procIds) {
    try {
        $proc = Get-Process -Id $procId -ErrorAction SilentlyContinue
        if ($proc) {
            Write-Host "Matando PID $procId ($($proc.Name))..." -ForegroundColor Cyan
            Stop-Process -Id $procId -Force
            Write-Host "PID $procId eliminado OK." -ForegroundColor Green
        }
    } catch {
        Write-Warning "No se pudo matar PID $procId`: $_"
    }
}
