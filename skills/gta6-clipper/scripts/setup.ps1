# GTA 6 Clipper setup for Windows. Checks what this PC needs, installs what's missing, says when it's ready.
# Safe to re-run any time.
#   powershell -NoProfile -ExecutionPolicy Bypass -File scripts\setup.ps1
#Requires -Version 5.1
$ErrorActionPreference = "Stop"
if (Get-Variable PSNativeCommandUseErrorActionPreference -ErrorAction SilentlyContinue) {
    $PSNativeCommandUseErrorActionPreference = $false
}

if ($env:OS -ne "Windows_NT") {
    Write-Host "This setup is for Windows. On a Mac run: bash scripts/setup.sh"
    exit 1
}

$SkillDir = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$Venv = Join-Path $SkillDir ".venv"
$Models = Join-Path $SkillDir "models"
$Bin = Join-Path $SkillDir "bin"
New-Item -ItemType Directory -Force -Path $Models, $Bin | Out-Null
$script:FAILED = 0

function ok($m)   { Write-Host "  [ok]      $m" }
function inst($m) { Write-Host "  [install] $m" }
function warn($m) { Write-Host "  [warn]    $m" }
function fail($m) { Write-Host "  [MISSING] $m"; $script:FAILED = 1 }

function Refresh-Path {
    $machine = [Environment]::GetEnvironmentVariable("Path", "Machine")
    $user = [Environment]::GetEnvironmentVariable("Path", "User")
    $env:Path = "$machine;$user;$Bin"
}

function Have($name) {
    return [bool](Get-Command $name -ErrorAction SilentlyContinue)
}

function Install-Winget($id) {
    if (-not (Have "winget")) { return $false }
    & winget install --id $id -e --accept-package-agreements --accept-source-agreements --disable-interactivity | Out-Null
    Refresh-Path
    return $true
}

Write-Host "GTA 6 Clipper setup (Windows)"
Refresh-Path

# 1. ffmpeg (cutting / encoding) and deno (YouTube downloads)
if (Have "ffmpeg") { ok "ffmpeg" } else {
    inst "ffmpeg"
    if ((Install-Winget "Gyan.FFmpeg") -and (Have "ffmpeg")) { ok "ffmpeg" } else { fail "ffmpeg (winget install --id Gyan.FFmpeg -e)" }
}
if (Have "deno") { ok "deno" } else {
    inst "deno"
    if ((Install-Winget "DenoLand.Deno") -and (Have "deno")) { ok "deno" } else { fail "deno (winget install --id DenoLand.Deno -e)" }
}
if (-not (Have "winget") -and $script:FAILED) {
    fail "winget (install App Installer from the Microsoft Store, then re-run setup)"
}

# 2. uv (downloads Python 3.12 and builds the venv)
$uv = $null
if (Have "uv") { $uv = (Get-Command uv).Source }
foreach ($cand in @(
    (Join-Path $env:USERPROFILE ".local\bin\uv.exe"),
    (Join-Path $env:USERPROFILE ".cargo\bin\uv.exe")
)) {
    if (-not $uv -and (Test-Path $cand)) { $uv = $cand }
}
if (-not $uv) {
    inst "uv"
    irm https://astral.sh/uv/install.ps1 | iex
    Refresh-Path
    if (Have "uv") { $uv = (Get-Command uv).Source }
    elseif (Test-Path (Join-Path $env:USERPROFILE ".local\bin\uv.exe")) { $uv = Join-Path $env:USERPROFILE ".local\bin\uv.exe" }
}
if ($uv) { ok "uv" } else { fail "uv (https://docs.astral.sh/uv/getting-started/installation/)" }

# 3. whisper.cpp (speech to text). Reuse one already on PATH.
$whisperExe = $null
if (Have "whisper-cli") { $whisperExe = (Get-Command whisper-cli).Source }
elseif (Test-Path (Join-Path $Bin "whisper-cli.exe")) { $whisperExe = Join-Path $Bin "whisper-cli.exe" }
if (-not $whisperExe) {
    inst "whisper.cpp (CPU build)"
    $tag = "b5454"  # whisper.cpp 1.9.5
    $arch = $env:PROCESSOR_ARCHITECTURE
    if ($arch -eq "ARM64") { $asset = "whisper-bin-win-cpu-arm64.zip" }
    elseif ($arch -eq "X86") { $asset = "whisper-bin-Win32.zip" }
    else { $asset = "whisper-bin-x64.zip" }
    $url = "https://github.com/ggml-org/whisper.cpp/releases/download/$tag/$asset"
    $zip = Join-Path $env:TEMP $asset
    $tmp = Join-Path $env:TEMP "whisper-gta6-unzip"
    & curl.exe -L --fail --retry 3 -o $zip $url
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path $zip)) {
        fail "whisper.cpp download ($url)"
    } else {
        $unpack = $true
        try {
            $rel = Invoke-RestMethod -Uri "https://api.github.com/repos/ggml-org/whisper.cpp/releases/tags/$tag" -Headers @{ "User-Agent" = "gta6-clipper" }
            $meta = $rel.assets | Where-Object { $_.name -eq $asset } | Select-Object -First 1
            $digest = ""
            if ($meta -and $meta.digest) { $digest = [string]$meta.digest }
            if ($digest.StartsWith("sha256:")) {
                $want = $digest.Substring(7).ToUpper()
                $got = (Get-FileHash $zip -Algorithm SHA256).Hash.ToUpper()
                if ($got -ne $want) {
                    $unpack = $false
                    fail "whisper.cpp checksum mismatch"
                } else { ok "whisper.cpp checksum" }
            } else {
                warn "no published checksum for $asset; continuing with the official zip"
            }
        } catch {
            warn "could not verify the whisper.cpp checksum ($_); continuing with the official zip"
        }
        if ($unpack) {
            if (Test-Path $tmp) { Remove-Item $tmp -Recurse -Force }
            Expand-Archive -Path $zip -DestinationPath $tmp -Force
            $exe = Get-ChildItem $tmp -Recurse -Filter whisper-cli.exe | Select-Object -First 1
            if (-not $exe) {
                fail "whisper-cli.exe was not in $asset"
            } else {
                Copy-Item (Join-Path $exe.DirectoryName "*") $Bin -Force
                $whisperExe = Join-Path $Bin "whisper-cli.exe"
                if (Test-Path $whisperExe) { ok "whisper.cpp" } else { fail "whisper.cpp" }
            }
        }
    }
} else {
    ok "whisper.cpp"
}

# 4. Python environment: yt-dlp (always latest), OpenCV (facecam), Pillow (captions)
$py = Join-Path $Venv "Scripts\python.exe"
if ($uv) {
    if (-not (Test-Path $py)) {
        inst "Python 3.12 environment"
        & $uv venv --python 3.12 $Venv
        if ($LASTEXITCODE -ne 0) { fail "Python 3.12 environment" }
    }
    if (Test-Path $py) {
        & $uv pip install --python $py -q -U "yt-dlp[default]" opencv-python-headless pillow numpy
        if ($LASTEXITCODE -ne 0) {
            fail "Python packages"
        } else {
            & $py -c "import yt_dlp, cv2, PIL, numpy"
            if ($LASTEXITCODE -ne 0) { fail "Python packages (import check)" } else { ok "Python packages (yt-dlp, opencv, pillow, numpy)" }
        }
    }
}

# 5. Whisper model (~465 MB). Reuse one that is already downloaded.
$whisperModel = ""
foreach ($cand in @(
    (Join-Path $Models "ggml-small.en.bin"),
    (Join-Path $Models "ggml-small.bin"),
    (Join-Path $env:USERPROFILE ".cache\whisper-cpp\ggml-small.en.bin"),
    (Join-Path $env:USERPROFILE ".cache\whisper-cpp\ggml-small.bin")
)) {
    if ((Test-Path $cand) -and ((Get-Item $cand).Length -gt 400MB)) { $whisperModel = $cand; break }
}
if (-not $whisperModel) {
    inst "Whisper small.en model (~465 MB)"
    $dest = Join-Path $Models "ggml-small.en.bin"
    & curl.exe -L --fail --retry 3 -o $dest "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-small.en.bin"
    if ($LASTEXITCODE -eq 0 -and (Test-Path $dest) -and ((Get-Item $dest).Length -gt 400MB)) {
        $whisperModel = $dest
    } else {
        fail "whisper model"
    }
}
if ($whisperModel) { ok "Whisper model: $whisperModel" }

# 6. Face detector (YuNet, ~230 KB)
$yunet = Join-Path $Models "face_detection_yunet_2023mar.onnx"
if (-not ((Test-Path $yunet) -and ((Get-Item $yunet).Length -gt 100KB))) {
    inst "YuNet face detector"
    & curl.exe -L --fail --retry 3 -o $yunet "https://github.com/opencv/opencv_zoo/raw/main/models/face_detection_yunet/face_detection_yunet_2023mar.onnx"
}
if ((Test-Path $yunet) -and ((Get-Item $yunet).Length -gt 100KB)) { ok "Face detector" } else { fail "Face detector" }

# 7. Caption font. Arial Black, then Impact, then Arial Bold. Windows ships at least one of these.
$windir = $env:WINDIR
if (-not $windir) { $windir = "C:\Windows" }
$font = @(
    (Join-Path $windir "Fonts\ariblk.ttf"),
    (Join-Path $windir "Fonts\impact.ttf"),
    (Join-Path $windir "Fonts\arialbd.ttf")
) | Where-Object { Test-Path $_ } | Select-Object -First 1
if ($font) { ok "Caption font ($font)" } else { fail "A caption font (Arial Black, Impact, or Arial Bold)" }

# 8. Free space. Audio-only downloads stay small, but say so early.
$drive = (Get-Item $SkillDir).PSDrive
if ($drive -and $drive.Free) {
    $freeGb = [math]::Round($drive.Free / 1GB, 1)
    if ($freeGb -lt 3) { warn "Only $freeGb GB free. Each stream needs about 0.5-1 GB while it runs." } else { ok "Disk space ($freeGb GB free)" }
}

$cfg = [ordered]@{
    whisper_model = $whisperModel
    whisper_bin   = $whisperExe
    yunet_model   = $yunet
}
$json = $cfg | ConvertTo-Json
[System.IO.File]::WriteAllText((Join-Path $SkillDir "config.json"), $json)

if ($script:FAILED -eq 0) {
    [System.IO.File]::WriteAllText((Join-Path $SkillDir ".ready"), (Get-Date).ToString("o"))
    Write-Host ""
    Write-Host "READY. Restart Claude Code, then say: clip today's GTA 6 videos"
    Write-Host "   or: live clip"
    Write-Host "You do not need to paste a link. Clips land in $env:USERPROFILE\GTA6-Clips"
} else {
    $ready = Join-Path $SkillDir ".ready"
    if (Test-Path $ready) { Remove-Item $ready -Force }
    Write-Host ""
    Write-Host "NOT READY: fix the [MISSING] items above and re-run setup."
    exit 1
}
