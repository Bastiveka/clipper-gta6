# Runs live.py with the gta6-clipper venv next to this skill.
#   powershell -NoProfile -ExecutionPolicy Bypass -File scripts\live.ps1 start
$ErrorActionPreference = "Stop"
$L = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$V = (Resolve-Path (Join-Path $L "..\gta6-clipper")).Path
$py = Join-Path $V ".venv\Scripts\python.exe"
if (-not (Test-Path $py)) {
    Write-Host "Set up the GTA 6 clipper first. Run: powershell -NoProfile -ExecutionPolicy Bypass -File `"$V\scripts\setup.ps1`""
    exit 1
}
& $py (Join-Path $L "scripts\live.py") @args
exit $LASTEXITCODE
