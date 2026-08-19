# Instala la status line de Claude Code en Windows (PowerShell 5.1 o 7+).
#   1. copia statusline.sh a ~\.claude\statusline.sh
#   2. registra el campo "statusLine" en ~\.claude\settings.json
# Es idempotente: se puede ejecutar tantas veces como se quiera.
$ErrorActionPreference = 'Stop'

$srcDir     = Split-Path -Parent $MyInvocation.MyCommand.Path
$claudeDir  = Join-Path $HOME '.claude'
$target     = Join-Path $claudeDir 'statusline.sh'
$settings   = Join-Path $claudeDir 'settings.json'

if (-not (Get-Command bash -ErrorAction SilentlyContinue)) {
  Write-Error "Falta 'bash'. Instala Git for Windows (incluye Git Bash)."
}

if (-not (Test-Path $claudeDir)) { New-Item -ItemType Directory -Path $claudeDir | Out-Null }
Copy-Item (Join-Path $srcDir 'statusline.sh') $target -Force
Write-Host "OK  script copiado -> $target"

# Ruta con barras normales: Claude Code lanza el comando a traves de cmd.exe.
$slPath  = $target -replace '\', '/'
$command = "bash `"$slPath`""

if (Test-Path $settings) {
  $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
  Copy-Item $settings "$settings.bak-$stamp" -Force
  Write-Host "OK  backup de settings.json creado"
  $json = Get-Content $settings -Raw | ConvertFrom-Json
} else {
  $json = [PSCustomObject]@{}
}

$statusLine = [PSCustomObject]@{ type = 'command'; command = $command; padding = 0 }
if ($json.PSObject.Properties.Name -contains 'statusLine') {
  $json.statusLine = $statusLine
} else {
  $json | Add-Member -NotePropertyName statusLine -NotePropertyValue $statusLine
}

$json | ConvertTo-Json -Depth 20 | Set-Content $settings -Encoding UTF8
Write-Host "OK  settings.json actualizado"
Write-Host ''
Write-Host 'Listo. Reinicia Claude Code (o abre una sesion nueva) para verlo.'
