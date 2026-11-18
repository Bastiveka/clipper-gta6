# Runs gta6clip.py with this skill's Windows venv.
#   powershell -NoProfile -ExecutionPolicy Bypass -File scripts\gta6.ps1 discover
$ErrorActionPreference = "Stop"
$S = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$py = Join-Path $S ".venv\Scripts\python.exe"
if (-not (Test-Path $py)) {
    Write-Host "Not set up yet. Run: powershell -NoProfile -ExecutionPolicy Bypass -File `"$PSScriptRoot\setup.ps1`""
    exit 1
}
& $py (Join-Path $S "scripts\gta6clip.py") @args
exit $LASTEXITCODE
