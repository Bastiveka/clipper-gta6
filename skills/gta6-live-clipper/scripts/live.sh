#!/usr/bin/env bash
# Runs live.py with the gta6-clipper venv next to this skill. Mac and Git Bash on Windows.
set -euo pipefail
L="$(cd "$(dirname "$0")/.." && pwd)"
V="$(cd "$L/../gta6-clipper" && pwd)"
if [[ -x "$V/.venv/Scripts/python.exe" ]]; then
  PY="$V/.venv/Scripts/python.exe"
elif [[ -x "$V/.venv/bin/python" ]]; then
  PY="$V/.venv/bin/python"
else
  echo "Set up the GTA 6 clipper first."
  echo "  Mac:     bash \"$V/scripts/setup.sh\""
  echo "  Windows: powershell -NoProfile -ExecutionPolicy Bypass -File \"$V/scripts/setup.ps1\""
  exit 1
fi
exec "$PY" "$L/scripts/live.py" "$@"
