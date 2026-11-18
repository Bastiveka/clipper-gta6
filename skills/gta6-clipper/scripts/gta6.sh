#!/usr/bin/env bash
# Runs gta6clip.py with this skill's venv. Works on Mac and in Git Bash on Windows.
set -euo pipefail
S="$(cd "$(dirname "$0")/.." && pwd)"
if [[ -x "$S/.venv/Scripts/python.exe" ]]; then
  PY="$S/.venv/Scripts/python.exe"
elif [[ -x "$S/.venv/bin/python" ]]; then
  PY="$S/.venv/bin/python"
else
  echo "Not set up yet."
  echo "  Mac:     bash \"$S/scripts/setup.sh\""
  echo "  Windows: powershell -NoProfile -ExecutionPolicy Bypass -File \"$S/scripts/setup.ps1\""
  exit 1
fi
exec "$PY" "$S/scripts/gta6clip.py" "$@"
